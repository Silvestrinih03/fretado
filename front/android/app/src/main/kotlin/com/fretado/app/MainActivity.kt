package com.fretado.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var navigationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fretado/navigation").setMethodCallHandler { call, result ->
            if (call.method != "start") {
                result.notImplemented()
            } else if (navigationResult != null) {
                result.error("navigation_busy", "A navegação já está aberta.", null)
            } else {
                val args = call.arguments as? Map<*, *>
                val session = NavigationSession.fromArguments(args)
                if (session == null) {
                    result.error("navigation_configuration", "Confira a sessão, o GPS e o token público Mapbox.", null)
                } else {
                    NavigationSession.active = session
                    navigationResult = result
                    try {
                        @Suppress("DEPRECATION")
                        startActivityForResult(Intent(this, FretadoNavigationActivity::class.java), 7401)
                    } catch (_: Exception) {
                        NavigationSession.active = null
                        navigationResult = null
                        result.error("navigation_unavailable", "Não foi possível iniciar a navegação.", null)
                    }
                }
            }
        }
    }

    @Deprecated("Used by the Flutter navigation bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 7401) {
            NavigationSession.active = null
            navigationResult?.success(data?.getStringExtra("message"))
            navigationResult = null
        }
    }
}
