package com.fretado.app

import android.Manifest
import android.annotation.SuppressLint
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.SystemClock
import android.speech.tts.TextToSpeech
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.mapbox.api.directions.v5.models.RouteOptions
import com.mapbox.common.MapboxOptions
import com.mapbox.common.location.Location
import com.mapbox.geojson.Feature
import com.mapbox.geojson.FeatureCollection
import com.mapbox.geojson.LineString
import com.mapbox.geojson.Point
import com.mapbox.geojson.utils.PolylineUtils
import com.mapbox.maps.CameraOptions
import com.mapbox.maps.MapView
import com.mapbox.maps.Style
import com.mapbox.maps.extension.style.layers.addLayer
import com.mapbox.maps.extension.style.layers.generated.LineLayer
import com.mapbox.maps.extension.style.layers.generated.CircleLayer
import com.mapbox.maps.extension.style.sources.addSource
import com.mapbox.maps.extension.style.sources.generated.GeoJsonSource
import com.mapbox.maps.extension.style.sources.generated.geoJsonSource
import com.mapbox.maps.extension.style.sources.getSourceAs
import com.mapbox.maps.plugin.locationcomponent.createDefault2DPuck
import com.mapbox.maps.plugin.locationcomponent.location
import com.mapbox.maps.plugin.gestures.gestures
import com.mapbox.maps.plugin.gestures.OnMoveListener
import com.mapbox.android.gestures.MoveGestureDetector
import com.mapbox.navigation.base.extensions.applyDefaultNavigationOptions
import com.mapbox.navigation.base.options.NavigationOptions
import com.mapbox.navigation.base.route.NavigationRoute
import com.mapbox.navigation.base.route.NavigationRouterCallback
import com.mapbox.navigation.base.route.RouterFailure
import com.mapbox.navigation.core.MapboxNavigation
import com.mapbox.navigation.core.MapboxNavigationProvider
import com.mapbox.navigation.core.directions.session.RoutesObserver
import com.mapbox.navigation.core.trip.session.BannerInstructionsObserver
import com.mapbox.navigation.core.trip.session.LocationMatcherResult
import com.mapbox.navigation.core.trip.session.LocationObserver
import com.mapbox.navigation.core.trip.session.RouteProgressObserver
import com.mapbox.navigation.core.trip.session.VoiceInstructionsObserver
import com.mapbox.navigation.ui.maps.location.NavigationLocationProvider
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import kotlin.math.ceil

/** A visible-only SDK session. Backend authorization is independent of routing. */
class FretadoNavigationActivity : ComponentActivity() {
    private lateinit var session: NavigationSession
    private lateinit var mapView: MapView
    private lateinit var maneuver: TextView
    private lateinit var distance: TextView
    private lateinit var estimate: TextView
    private lateinit var destinationLabel: TextView
    private lateinit var notice: TextView
    private val io = Executors.newSingleThreadScheduledExecutor()
    private var polling: ScheduledFuture<*>? = null
    private var navigation: MapboxNavigation? = null
    private val locationProvider = NavigationLocationProvider()
    private var speech: TextToSpeech? = null
    private var speechReady = false
    private var muted = false
    private var follow = true
    @Volatile private var visible = false
    private var target: Point? = null
    private var targetKey: String? = null
    private var routeVersion = 0
    private var routeRequested = false
    private var lastAuthorized = 0L
    private var lastRouteRequest = 0L
    private var currentRoute: NavigationRoute? = null
    @Volatile private var latestPosition: Point? = null
    @Volatile private var lastFix = 0L
    @Volatile private var activeConnection: HttpURLConnection? = null

    private val routesObserver = RoutesObserver { update ->
        currentRoute = update.navigationRoutes.firstOrNull()
        drawRoute()
    }

    private val banners = BannerInstructionsObserver { banner ->
        val primary = banner.primary()
        val arrow = when (primary.modifier()) {
            "left", "slight left", "sharp left" -> "↰"
            "right", "slight right", "sharp right" -> "↱"
            "uturn" -> "↶"
            else -> "↑"
        }
        maneuver.text = "$arrow  ${primary.text()}"
    }

    private val voices = VoiceInstructionsObserver { instruction ->
        if (visible && speechReady && !muted) {
            speech?.speak(instruction.announcement(), TextToSpeech.QUEUE_FLUSH, null, "freight-maneuver")
        }
    }

    private val progress = RouteProgressObserver { route ->
        val remaining = route.currentLegProgress?.currentStepProgress?.distanceRemaining?.toDouble() ?: 0.0
        distance.text = if (remaining >= 1000) String.format(Locale("pt", "BR"), "Em %.1f km", remaining / 1000) else "Em ${remaining.toInt()} m"
        val minutes = ceil(route.durationRemaining / 60).toInt().coerceAtLeast(1)
        val arrival = SimpleDateFormat("HH:mm", Locale("pt", "BR")).format(Date(System.currentTimeMillis() + (route.durationRemaining * 1000).toLong()))
        estimate.text = String.format(Locale("pt", "BR"), "%d min   •   %.1f km   •   chegada %s", minutes, route.distanceRemaining / 1000, arrival)
        if (route.distanceRemaining < 30) {
            notice.text = "Você está perto do destino. Confirme a coleta ou entrega na corrida."
        }
    }

    private val locations = object : LocationObserver {
        override fun onNewRawLocation(rawLocation: Location) = Unit
        override fun onNewLocationMatcherResult(locationMatcherResult: LocationMatcherResult) {
            val location = locationMatcherResult.enhancedLocation
            latestPosition = Point.fromLngLat(location.longitude, location.latitude)
            lastFix = SystemClock.elapsedRealtime()
            locationProvider.changePosition(location, locationMatcherResult.keyPoints)
            if (follow) mapView.mapboxMap.setCamera(CameraOptions.Builder()
                .center(latestPosition).zoom(16.5).bearing(location.bearing ?: 0.0).build())
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val activeSession = NavigationSession.active
        if (activeSession == null) { finish(); return }
        session = activeSession
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            close("Permita localização precisa para navegar."); return
        }
        MapboxOptions.accessToken = session.mapboxToken
        latestPosition = Point.fromLngLat(session.longitude, session.latitude)
        lastFix = SystemClock.elapsedRealtime()
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        buildLayout()
        speech = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val available = speech?.setLanguage(Locale("pt", "BR"))
                speechReady = available != TextToSpeech.LANG_MISSING_DATA && available != TextToSpeech.LANG_NOT_SUPPORTED
                if (!speechReady) notice.text = "Instale a voz em português nas configurações do Android."
            }
        }
    }

    private fun buildLayout() {
        val root = FrameLayout(this)
        mapView = MapView(this)
        mapView.gestures.addOnMoveListener(object : OnMoveListener {
            override fun onMoveBegin(detector: MoveGestureDetector) { follow = false }
            override fun onMove(detector: MoveGestureDetector): Boolean = false
            override fun onMoveEnd(detector: MoveGestureDetector) = Unit
        })
        root.addView(mapView, FrameLayout.LayoutParams(-1, -1))
        mapView.mapboxMap.setCamera(CameraOptions.Builder().center(latestPosition).zoom(15.0).build())
        mapView.mapboxMap.loadStyle(Style.LIGHT) { style ->
            style.addSource(geoJsonSource("freight-route") { featureCollection(FeatureCollection.fromFeatures(listOf<Feature>())) })
            style.addLayer(LineLayer("freight-route-border", "freight-route").lineColor(Color.WHITE).lineWidth(10.0))
            style.addLayer(LineLayer("freight-route-line", "freight-route").lineColor(Color.rgb(169, 134, 24)).lineWidth(6.0))
            style.addSource(geoJsonSource("freight-target") { featureCollection(FeatureCollection.fromFeatures(listOf<Feature>())) })
            style.addLayer(CircleLayer("freight-target-dot", "freight-target").circleColor(Color.rgb(43, 43, 43)).circleRadius(9.0).circleStrokeColor(Color.WHITE).circleStrokeWidth(3.0))
            drawRoute()
        }
        mapView.location.apply {
            setLocationProvider(locationProvider)
            locationPuck = createDefault2DPuck(withBearing = true)
            enabled = true
        }
        val top = panel()
        distance = text(13, Color.rgb(205, 177, 63))
        maneuver = text(23, Color.WHITE).apply { text = "Preparando navegação…"; setTypeface(null, Typeface.BOLD) }
        top.setBackgroundColor(Color.rgb(43, 43, 43))
        top.addView(distance); top.addView(maneuver)
        root.addView(top, FrameLayout.LayoutParams(-1, -2, Gravity.TOP).apply { setMargins(dp(12), dp(12), dp(12), 0) })
        val bottom = panel()
        destinationLabel = text(14, Color.rgb(43, 43, 43))
        estimate = text(19, Color.rgb(43, 43, 43)).apply { setTypeface(null, Typeface.BOLD) }
        notice = text(12, Color.DKGRAY).apply { text = "Conferindo a corrida…" }
        bottom.addView(destinationLabel); bottom.addView(estimate); bottom.addView(notice)
        val actions = LinearLayout(this)
        fun action(label: String, callback: () -> Unit) {
            actions.addView(Button(this).apply { text = label; isAllCaps = false; setOnClickListener { callback() } }, LinearLayout.LayoutParams(0, dp(48), 1f))
        }
        action("Centralizar") { follow = true; latestPosition?.let { mapView.mapboxMap.setCamera(CameraOptions.Builder().center(it).zoom(16.5).build()) } }
        action("Áudio ligado") {
            muted = !muted
            if (muted) speech?.stop()
            (actions.getChildAt(1) as Button).text = if (muted) "Áudio desligado" else "Áudio ligado"
        }
        bottom.addView(actions)
        bottom.addView(Button(this).apply {
            text = "Voltar à corrida"; isAllCaps = false
            setOnClickListener { close(null) }
        })
        // Attribution stays unobstructed above the bottom card.
        root.addView(bottom, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM).apply { setMargins(dp(12), 0, dp(12), dp(42)) })
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            insets
        }
        setContentView(root)
    }

    override fun onStart() {
        super.onStart()
        if (!::session.isInitialized || !::mapView.isInitialized || isFinishing) return
        visible = true
        polling = io.scheduleWithFixedDelay({ refreshContext() }, 0, 6, TimeUnit.SECONDS)
    }

    private fun refreshContext() {
        if (!visible) return
        try {
            val result = request("/rides/${session.rideId}/navigation/context")
            if (result.first in listOf(401, 403, 404, 409)) {
                runOnUiThread { close("A corrida mudou ou não está mais disponível para navegação.") }; return
            }
            if (result.first != 200) throw IllegalStateException()
            val context = JSONObject(result.second)
            runOnUiThread {
                if (visible && !isFinishing) {
                    runCatching { applyContext(context) }.onFailure {
                        close("Não foi possível preparar a navegação. Tente novamente.")
                    }
                }
            }
            val point = latestPosition
            if (point != null && SystemClock.elapsedRealtime() - lastFix < 15000 && visible) {
                val location = JSONObject().put("latitude", String.format(Locale.US, "%.6f", point.latitude()))
                    .put("longitude", String.format(Locale.US, "%.6f", point.longitude()))
                val sent = request("/driver-locations/me/location", location)
                if (sent.first == 401 || sent.first == 403) runOnUiThread { close("Sua sessão mudou. Entre novamente para navegar.") }
            }
        } catch (_: Exception) {
            runOnUiThread {
                if (visible) {
                    notice.text = "Sem atualização da corrida. Verifique sua conexão."
                    if (lastAuthorized != 0L && SystemClock.elapsedRealtime() - lastAuthorized > 20000) {
                        close("Navegação pausada: não foi possível confirmar a corrida. Tente novamente.")
                    }
                }
            }
        }
    }

    private fun request(path: String, body: JSONObject? = null): Pair<Int, String> {
        val connection = URL(session.apiBaseUrl + path).openConnection() as HttpURLConnection
        activeConnection = connection
        try {
            connection.connectTimeout = 8000; connection.readTimeout = 8000
            connection.instanceFollowRedirects = false
            connection.setRequestProperty("Authorization", "Bearer ${session.bearer}")
            connection.setRequestProperty("Accept", "application/json")
            if (body != null) {
                connection.requestMethod = "PUT"; connection.doOutput = true
                connection.setRequestProperty("Content-Type", "application/json")
                connection.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            }
            val status = connection.responseCode
            val content = (if (status in 200..299) connection.inputStream else connection.errorStream)
                ?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }.orEmpty()
            return status to content
        } finally { connection.disconnect(); activeConnection = null }
    }

    private fun applyContext(context: JSONObject) {
        lastAuthorized = SystemClock.elapsedRealtime()
        val destination = context.getJSONObject("destination")
        val point = Point.fromLngLat(destination.getDouble("longitude"), destination.getDouble("latitude"))
        val key = "${context.getInt("status_id")}:${point.longitude()}:${point.latitude()}"
        destinationLabel.text = "${if (context.getString("leg") == "pickup") "COLETA" else "ENTREGA"} · ${destination.getString("address")}"
        val staleGps = SystemClock.elapsedRealtime() - lastFix > 15000
        notice.text = if (staleGps) "Aguardando sinal de GPS. A posição pode estar desatualizada." else "Orientação ativa. Confirme a conclusão na tela da corrida."
        if (key != targetKey) {
            targetKey = key; target = point; routeVersion++
            routeRequested = false; currentRoute = null
            navigation?.stopTripSession()
            navigation?.setNavigationRoutes(emptyList())
            speech?.stop()
        }
        if (!routeRequested && SystemClock.elapsedRealtime() - lastRouteRequest >= 5000) requestRoute()
    }

    @SuppressLint("MissingPermission")
    private fun requestRoute() {
        val origin = latestPosition ?: return
        val destination = target ?: return
        lastRouteRequest = SystemClock.elapsedRealtime()
        routeRequested = true
        val version = routeVersion
        val nav = navigation ?: MapboxNavigationProvider.create(NavigationOptions.Builder(this).build()).also {
            navigation = it
            it.registerLocationObserver(locations)
            it.registerRoutesObserver(routesObserver)
            it.registerRouteProgressObserver(progress)
            it.registerBannerInstructionsObserver(banners)
            it.registerVoiceInstructionsObserver(voices)
        }
        nav.requestRoutes(RouteOptions.builder().applyDefaultNavigationOptions()
            .coordinatesList(listOf(origin, destination)).language("pt-BR").voiceUnits("metric").build(),
            object : NavigationRouterCallback {
                override fun onRoutesReady(routes: List<NavigationRoute>, routerOrigin: String) {
                    if (!visible || version != routeVersion || isFinishing || routes.isEmpty()) return
                    nav.setNavigationRoutes(routes)
                    // Set the route first, avoiding an unnecessary Free Drive session.
                    nav.startTripSession(withForegroundService = false)
                }
                override fun onFailure(reasons: List<RouterFailure>, routeOptions: RouteOptions) {
                    if (visible && version == routeVersion) {
                        routeRequested = false
                        notice.text = "Não foi possível calcular a rota. Tentaremos novamente."
                    }
                }
                override fun onCanceled(routeOptions: RouteOptions, routerOrigin: String) {
                    if (visible && version == routeVersion) routeRequested = false
                }
            })
    }

    private fun drawRoute() {
        val style = mapView.mapboxMap.style ?: return
        val geometry = currentRoute?.directionsRoute?.geometry()
        if (geometry != null) {
            val line = LineString.fromLngLats(PolylineUtils.decode(geometry, 6))
            style.getSourceAs<GeoJsonSource>("freight-route")?.feature(Feature.fromGeometry(line))
        } else {
            style.getSourceAs<GeoJsonSource>("freight-route")?.featureCollection(FeatureCollection.fromFeatures(listOf<Feature>()))
        }
        target?.let { style.getSourceAs<GeoJsonSource>("freight-target")?.feature(Feature.fromGeometry(it)) }
    }

    override fun onPause() {
        visible = false
        routeVersion++
        polling?.cancel(true); polling = null
        activeConnection?.disconnect()
        speech?.stop()
        navigation?.let {
            it.unregisterLocationObserver(locations)
            it.unregisterRoutesObserver(routesObserver)
            it.unregisterRouteProgressObserver(progress)
            it.unregisterBannerInstructionsObserver(banners)
            it.unregisterVoiceInstructionsObserver(voices)
            it.stopTripSession()
            MapboxNavigationProvider.destroy()
        }
        navigation = null
        super.onPause()
    }

    override fun onStop() {
        super.onStop()
        // Returning opens the Flutter controls; starting again rechecks GPS/auth.
        if (!isFinishing) finish()
    }

    override fun onDestroy() {
        io.shutdownNow(); speech?.shutdown(); speech = null
        super.onDestroy()
    }

    private fun close(message: String?) {
        if (isFinishing) return
        setResult(RESULT_OK, Intent().putExtra("message", message))
        finish()
    }

    private fun panel() = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(16), dp(14), dp(16), dp(12))
        background = GradientDrawable().apply { setColor(Color.WHITE); cornerRadius = dp(18).toFloat() }
        elevation = dp(4).toFloat()
    }
    private fun text(size: Int, color: Int) = TextView(this).apply {
        textSize = size.toFloat(); setTextColor(color); setPadding(0, dp(3), 0, dp(3))
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
