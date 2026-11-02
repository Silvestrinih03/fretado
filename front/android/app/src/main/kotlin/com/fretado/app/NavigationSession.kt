package com.fretado.app

import java.net.URI

/** Tokens live only in memory, never in Intent extras, saved state or logs. */
data class NavigationSession(
    val rideId: Long,
    val apiBaseUrl: String,
    val bearer: String,
    val mapboxToken: String,
    val latitude: Double,
    val longitude: Double,
) {
    companion object {
        var active: NavigationSession? = null

        fun fromArguments(args: Map<*, *>?): NavigationSession? {
            if (args == null) return null
            val id = (args["rideId"] as? Number)?.toLong() ?: return null
            val base = (args["apiBaseUrl"] as? String)?.trimEnd('/') ?: return null
            val bearer = args["accessToken"] as? String ?: return null
            val token = args["mapboxToken"] as? String ?: return null
            val lat = (args["latitude"] as? Number)?.toDouble() ?: return null
            val lon = (args["longitude"] as? Number)?.toDouble() ?: return null
            val uri = runCatching { URI(base) }.getOrNull() ?: return null
            if (id <= 0 || uri.scheme !in listOf("http", "https") || uri.host.isNullOrBlank()
                || bearer.isBlank() || !token.startsWith("pk.")
                || !lat.isFinite() || !lon.isFinite() || lat !in -90.0..90.0 || lon !in -180.0..180.0) return null
            return NavigationSession(id, base, bearer, token, lat, lon)
        }
    }
}
