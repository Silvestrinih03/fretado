import 'package:flutter/material.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/services/http_service.dart';
import '../../../../core/services/myself/models/myself_user_model.dart';
import '../../data/datasources/profile_datasource.dart';
import '../../data/models/avatar_image.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/services/avatar_image_picker.dart';
import '../controllers/profile_controller.dart';
import 'profile_widgets.dart';

/// One photo flow shared by the profile and personal-data screens.
class EditableProfileAvatar extends StatefulWidget {
  final int userId;
  final String name;
  final String? avatarUrl;
  final double size;
  final bool enabled;
  final ValueChanged<bool>? onBusyChanged;
  final AvatarImagePicker? picker;
  final ProfileController? controller;

  const EditableProfileAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.size = 60,
    this.enabled = true,
    this.onBusyChanged,
    this.picker,
    this.controller,
  });

  @override
  State<EditableProfileAvatar> createState() => _EditableProfileAvatarState();
}

class _EditableProfileAvatarState extends State<EditableProfileAvatar> {
  late final AvatarImagePicker _picker;
  late final ProfileController _controller;
  HttpService? _http;
  String? _url;
  bool _busy = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.avatarUrl;
    _picker = widget.picker ?? DeviceAvatarImagePicker();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _http = HttpService();
      _controller = ProfileController(
        ProfileRepositoryImpl(ProfileDatasource(_http!)),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _recover());
  }

  @override
  void didUpdateWidget(covariant EditableProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl ||
        oldWidget.userId != widget.userId) {
      _url = widget.avatarUrl;
    }
  }

  @override
  void dispose() {
    _http?.dispose();
    super.dispose();
  }

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusyChanged?.call(busy);
  }

  Future<void> _recover() async {
    if (!mounted || _busy || !widget.enabled) return;
    // Gallery recovery may return immediately on web/iOS. Avoid notifying the
    // parent until an interrupted Android selection actually exists.
    try {
      final image = await _picker.recoverLostImage();
      if (!mounted || image == null || _busy || !widget.enabled) return;
      _setBusy(true);
      try {
        await _previewAndUpload(image);
      } finally {
        if (mounted) _setBusy(false);
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      AvatarSelectionException e => e.message,
      ProfileControllerException e => e.message,
      ProfileRepositoryException e => e.message,
      _ => 'Não foi possível atualizar sua foto. Tente novamente.',
    };
    showFretErrorPopup(context, message: message);
  }

  Future<void> _edit() async {
    if (_busy || !widget.enabled) return;
    _setBusy(true);
    try {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher foto'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              if (_picker.supportsCamera)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Tirar foto'),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
              if (_url != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remover foto'),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              ListTile(
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
      if (!mounted || action == null) return;
      if (action == 'remove') {
        await _remove();
      } else {
        final image = await _picker.pick(
          action == 'camera' ? AvatarSource.camera : AvatarSource.gallery,
        );
        if (mounted && image != null) await _previewAndUpload(image);
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _previewAndUpload(AvatarImage image) async {
    bool validImage = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Confirmar foto de perfil'),
          content: SizedBox(
            width: 220,
            height: 220,
            child: ClipOval(
              child: Image.memory(
                image.bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  if (validImage) {
                    validImage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) updateDialog(() {});
                    });
                  }
                  return const Center(
                    child: Text('Não foi possível abrir a imagem.'),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: validImage ? () => Navigator.pop(context, true) : null,
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || confirmed != true || !validImage) return;
    setState(() => _uploading = true);
    final MyselfUserModel user;
    try {
      user = await _controller.uploadAvatar(
        userId: widget.userId,
        image: image,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
    if (!mounted) return;
    setState(() => _url = user.avatarUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto atualizada com sucesso.')),
    );
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover foto de perfil?'),
        content: const Text('Suas iniciais serão exibidas no lugar da foto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _uploading = true);
    final MyselfUserModel user;
    try {
      user = await _controller.removeAvatar(userId: widget.userId);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
    if (!mounted) return;
    setState(() => _url = user.avatarUrl);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Foto removida com sucesso.')));
  }

  @override
  Widget build(BuildContext context) => ProfileAvatar(
    name: widget.name,
    imageUrl: _url,
    size: widget.size,
    isLoading: _uploading,
    onTap: widget.enabled ? _edit : null,
  );
}
