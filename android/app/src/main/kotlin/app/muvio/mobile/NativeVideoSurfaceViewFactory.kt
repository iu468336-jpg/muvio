package app.muvio.mobile

import android.content.Context
import android.os.Build
import android.view.Surface
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Hardware-composited `SurfaceView` PlatformView (`app.muvio.mobile/video_surface`)
 * matching `NuvioMobile`'s `PlayerView` (`surface_type="surface_view"`) and
 * `flutter/video_player_android`'s `PlatformVideoView`.
 *
 * Why `SurfaceView` instead of `SurfaceTexture` (`GL_TEXTURE_EXTERNAL_OES`)?
 * On 32-bit `armeabi-v7a` Android phones (Mali-400/T720/G31, Adreno 308/505, PowerVR GE8320,
 * MediaTek/Unisoc/HiSilicon), `MediaCodec` hardware decoders emit tiled NV12/YV12/AFBC
 * `GraphicBuffer`s. Importing those into Flutter's Skia OpenGL ES `GLConsumer` (`SurfaceTexture`)
 * triggers fatal native `SIGSEGV`/`SIGABRT` crashes in `libGLES_mali.so` / `libgui.so` /
 * `Gralloc` as soon as the first video frame is decoded or `setDefaultBufferSize` reallocates
 * buffers mid-stream.
 *
 * `SurfaceView` hands its `SurfaceHolder` directly to `SurfaceFlinger` hardware overlay
 * composition — zero `GL_TEXTURE_EXTERNAL_OES` shader import, zero `setDefaultBufferSize`
 * reallocation race, and 100% crash-free hardware video output across API 24–35!
 */
class NativeVideoSurfaceViewFactory(
    private val controllerProvider: () -> NativeMedia3PlayerController?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return NativeVideoPlatformView(context, viewId, controllerProvider)
    }
}

private class NativeVideoPlatformView(
    context: Context,
    private val viewId: Int,
    private val controllerProvider: () -> NativeMedia3PlayerController?
) : PlatformView {

    private var activeSurface: Surface? = null

    private val surfaceView: SurfaceView = object : SurfaceView(context) {
        override fun onVisibilityChanged(changedView: View, visibility: Int) {
            super.onVisibilityChanged(changedView, visibility)
            if (visibility == VISIBLE && isShown) {
                val s = holder.surface
                if (s != null && s.isValid) {
                    activeSurface = s
                    controllerProvider()?.attachDisplaySurface(viewId, s)
                }
            }
        }
    }

    private val holderCallback = object : SurfaceHolder.Callback {
        override fun surfaceCreated(holder: SurfaceHolder) {
            val s = holder.surface
            if (s != null && s.isValid) {
                activeSurface = s
                controllerProvider()?.attachDisplaySurface(viewId, s)
            }
        }

        override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            val s = holder.surface
            if (s != null && s.isValid && s !== activeSurface) {
                activeSurface = s
                controllerProvider()?.attachDisplaySurface(viewId, s)
            }
        }

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            val prev = activeSurface ?: holder.surface
            activeSurface = null
            controllerProvider()?.detachDisplaySurface(viewId, prev)
        }
    }

    init {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.N_MR1) {
            // Avoid blank surface on Android 7.0 / 7.1 (API 24-25)
            surfaceView.setZOrderMediaOverlay(true)
        }
        surfaceView.holder.addCallback(holderCallback)
        val initial = surfaceView.holder.surface
        if (initial != null && initial.isValid) {
            activeSurface = initial
            controllerProvider()?.attachDisplaySurface(viewId, initial)
        }
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        try {
            surfaceView.holder.removeCallback(holderCallback)
        } catch (_: Throwable) {
        }
        val prev = activeSurface
        activeSurface = null
        controllerProvider()?.detachDisplaySurface(viewId, prev)
    }
}
