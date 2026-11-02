package com.fretado.app

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import com.mapbox.bindgen.Value
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.plugin.attribution.attribution
import com.mapbox.maps.plugin.logo.logo
import com.mapbox.maps.plugin.scalebar.scalebar
import io.flutter.FlutterInjector
import org.json.JSONObject

/** Same style patches as Flutter; no remote custom style/account setup needed. */
object FretMapAppearance {
    fun load(context: Context): JSONObject = runCatching {
        val key = FlutterInjector.instance().flutterLoader()
            .getLookupKeyForAsset("assets/maps/fret_map_theme.json")
        context.assets.open(key).bufferedReader(Charsets.UTF_8).use { JSONObject(it.readText()) }
    }.getOrElse { JSONObject() }

    fun apply(style: Style, theme: JSONObject) {
        val layers = theme.optJSONArray("layers") ?: return
        for (index in 0 until layers.length()) {
            runCatching {
                val patch = layers.getJSONObject(index)
                val id = patch.getString("id")
                if (style.styleLayerExists(id)) {
                    val raw = patch.get("value")
                    val json = if (raw is String) JSONObject.quote(raw) else raw.toString()
                    Value.fromJson(json).value?.let { value ->
                        style.setStyleLayerProperty(id, patch.getString("property"), value)
                    }
                }
            }
        }
    }

    fun configureOrnaments(map: MapView) {
        val density = map.resources.displayMetrics.density
        map.scalebar.enabled = false
        map.logo.updateSettings {
            position = Gravity.BOTTOM or Gravity.START
            marginLeft = 8f * density
            marginBottom = 8f * density
        }
        map.attribution.updateSettings {
            position = Gravity.BOTTOM or Gravity.START
            marginLeft = 96f * density
            marginBottom = 8f * density
            iconColor = Color.rgb(119, 116, 108)
        }
    }
}
