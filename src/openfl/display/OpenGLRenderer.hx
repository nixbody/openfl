package openfl.display;


import lime.graphics.opengl.ext.KHR_debug;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.GLRenderContext;
import lime.math.Matrix4;
import lime.utils.Float32Array;
import openfl._internal.renderer.opengl.GLMaskShader;
import openfl._internal.renderer.ShaderBuffer;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectShader;
import openfl.display.Graphics;
import openfl.display.GraphicsShader;
import openfl.display.Stage;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(openfl._internal.renderer.ShaderBuffer)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
@:access(openfl.display.Graphics)
@:access(openfl.display.IBitmapDrawable)
@:access(openfl.display.Shader)
@:access(openfl.display.ShaderParameter)
@:access(openfl.display.Stage3D)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
@:allow(openfl._internal.renderer.opengl)
@:allow(openfl.display3D.textures)
@:allow(openfl.display3D)
@:allow(openfl.display)


class OpenGLRenderer extends DisplayObjectRenderer {
	
	
	private static var __alphaValue = [ 1. ];
	private static var __colorMultipliersValue = [ 0, 0, 0, 0. ];
	private static var __colorOffsetsValue = [ 0, 0, 0, 0. ];
	private static var __defaultColorMultipliersValue = [ 1, 1, 1, 1. ];
	private static var __emptyColorValue = [ 0, 0, 0, 0. ];
	private static var __emptyAlphaValue = [ 1. ];
	private static var __hasColorTransformValue = [ false ];
	
	public var gl:GLRenderContext;
	
	private var __clipRects:Array<Rectangle>;
	private var __currentDisplayShader:Shader;
	private var __currentGraphicsShader:Shader;
	private var __currentRenderTarget:BitmapData;
	private var __currentShader:Shader;
	private var __currentShaderBuffer:ShaderBuffer;
	private var __defaultDisplayShader:DisplayObjectShader;
	private var __defaultGraphicsShader:GraphicsShader;
	private var __defaultRenderTarget:BitmapData;
	private var __defaultShader:Shader;
	private var __displayHeight:Int;
	private var __displayWidth:Int;
	private var __flipped:Bool;
	private var __height:Int;
	private var __maskShader:GLMaskShader;
	private var __matrix:Matrix4;
	private var __renderTargetA:BitmapData;
	private var __renderTargetB:BitmapData;
	private var __maskObjects:Array<DisplayObject>;
	private var __numClipRects:Int;
	private var __offsetX:Int;
	private var __offsetY:Int;
	private var __projection:Matrix4;
	private var __projectionFlipped:Matrix4;
	private var __softwareRenderer:DisplayObjectRenderer;
	private var __stencilReference:Int;
	private var __tempRect:Rectangle;
	private var __upscaled:Bool;
	private var __values:Array<Float>;
	private var __width:Int;
	
	
	private function new (gl:GLRenderContext, ?defaultRenderTarget:BitmapData) {
		
		super ();
		
		this.gl = gl;
		this.__defaultRenderTarget = defaultRenderTarget;
		this.__flipped = (__defaultRenderTarget == null);
		
		if (Graphics.maxTextureWidth == null) {
			
			Graphics.maxTextureWidth = Graphics.maxTextureHeight = gl.getInteger (gl.MAX_TEXTURE_SIZE);
			
		}
		
		__matrix = new Matrix4 ();
		__values = new Array ();
		
		#if gl_debug
		var ext:KHR_debug = gl.getExtension ("KHR_debug");
		if (ext != null) {
			
			gl.enable (ext.DEBUG_OUTPUT);
			gl.enable (ext.DEBUG_OUTPUT_SYNCHRONOUS);
			
		}
		#end
		
		#if (js && html5)
		__softwareRenderer = new CanvasRenderer (null);
		#else
		__softwareRenderer = new CairoRenderer (null);
		#end
		
		__type = OPENGL;
		
		__setBlendMode (NORMAL);
		gl.enable (gl.BLEND);
		
		__clipRects = new Array ();
		__maskObjects = new Array ();
		__numClipRects = 0;
		__stencilReference = 0;
		__tempRect = new Rectangle ();
		
		__defaultDisplayShader = new DisplayObjectShader ();
		__defaultGraphicsShader = new GraphicsShader ();
		__defaultShader = __defaultDisplayShader;
		
		__initShader (__defaultShader);
		
		__maskShader = new GLMaskShader ();
		
	}
	
	
	public function applyAlpha (alpha:Float):Void {
		
		__alphaValue[0] = alpha;
		
		if (__currentShaderBuffer != null) {
			
			__currentShaderBuffer.addOverride ("openfl_Alpha", __alphaValue);
			
		} else if (__currentShader != null) {
			
			if (__currentShader.__alpha != null) __currentShader.__alpha.value = __alphaValue;
			
		}
		
	}
	
	
	public function applyBitmapData (bitmapData:BitmapData, smooth:Bool, repeat:Bool = false):Void {
		
		if (__currentShader.__bitmap != null) {
			
			__currentShader.__bitmap.input = bitmapData;
			__currentShader.__bitmap.filter = smooth ? LINEAR : NEAREST;
			__currentShader.__bitmap.mipFilter = MIPNONE;
			__currentShader.__bitmap.wrap = repeat ? REPEAT : CLAMP;
			
		}
		
		if (__currentShader.__texture != null) {
			
			__currentShader.__texture.input = bitmapData;
			__currentShader.__texture.filter = smooth ? LINEAR : NEAREST;
			__currentShader.__texture.mipFilter = MIPNONE;
			__currentShader.__texture.wrap = repeat ? REPEAT : CLAMP;
			
		}
		
	}
	
	
	public function applyColorTransform (colorTransform:ColorTransform):Void {
		
		var enabled = (colorTransform != null && !colorTransform.__isDefault ());
		applyHasColorTransform (enabled);
		
		if (enabled) {
			
			colorTransform.__setArrays (__colorMultipliersValue, __colorOffsetsValue);
			
			if (__currentShaderBuffer != null) {
				
				__currentShaderBuffer.addOverride ("openfl_ColorMultiplier", __colorMultipliersValue);
				__currentShaderBuffer.addOverride ("openfl_ColorOffset", __colorOffsetsValue);
				
			} else if (__currentShader != null) {
				
				if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.value = __colorMultipliersValue;
				if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.value = __colorOffsetsValue;
				
			}
			
		} else {
			
			if (__currentShaderBuffer != null) {
				
				__currentShaderBuffer.addOverride ("openfl_ColorMultiplier", __emptyColorValue);
				__currentShaderBuffer.addOverride ("openfl_ColorOffset", __emptyColorValue);
				
			} else if (__currentShader != null) {
				
				if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.value = __emptyColorValue;
				if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.value = __emptyColorValue;
				
			}
			
		}
		
	}
	
	
	public function applyHasColorTransform (enabled:Bool):Void {
		
		__hasColorTransformValue[0] = enabled;
		
		if (__currentShaderBuffer != null) {
			
			__currentShaderBuffer.addOverride ("openfl_HasColorTransform", __hasColorTransformValue);
			
		} else if (__currentShader != null) {
			
			if (__currentShader.__hasColorTransform != null) __currentShader.__hasColorTransform.value = __hasColorTransformValue;
			
		}
		
	}
	
	
	public function applyMatrix (matrix:Array<Float>):Void {
		
		if (__currentShaderBuffer != null) {
			
			__currentShaderBuffer.addOverride ("openfl_Matrix", matrix);
			
		} else if (__currentShader != null) {
			
			if (__currentShader.__matrix != null) __currentShader.__matrix.value = matrix;
			
		}
		
	}
	
	
	public function getMatrix (transform:Matrix):Matrix4 {
		
		if (gl != null) {
			
			var values = __getMatrix (transform);
			
			for (i in 0...16) {
				
				__matrix[i] = values[i];
				
			}
			
			return __matrix;
			
		} else {
			
			__matrix.identity ();
			__matrix[0] = transform.a;
			__matrix[1] = transform.b;
			__matrix[4] = transform.c;
			__matrix[5] = transform.d;
			__matrix[12] = transform.tx;
			__matrix[13] = transform.ty;
			
			return __matrix;
			
		}
		
	}
	
	
	public function setShader (shader:Shader):Void {
		
		__currentShaderBuffer = null;
		
		if (__currentShader == shader) return;
		
		if (__currentShader != null) {
			
			__currentShader.__disable ();
			
		}
		
		if (shader == null) {
			
			__currentShader = null;
			gl.useProgram (null);
			return;
			
		} else {
			
			__currentShader = shader;
			__initShader (shader);
			gl.useProgram (shader.glProgram);
			__currentShader.__enable ();
			
		}
		
	}
	
	
	public function setViewport ():Void {
		
		gl.viewport (__offsetX, __offsetY, __displayWidth, __displayHeight);
		
	}
	
	
	public function updateShader ():Void {
		
		if (__currentShader != null) {
			
			if (__currentShader.__position != null) __currentShader.__position.__useArray = true;
			if (__currentShader.__texCoord != null) __currentShader.__texCoord.__useArray = true;
			__currentShader.__update ();
			
		}
		
	}
	
	
	public function useAlphaArray ():Void {
		
		if (__currentShader != null) {
			
			if (__currentShader.__alpha != null) __currentShader.__alpha.__useArray = true;
			
		}
		
	}
	
	
	public function useColorTransformArray ():Void {
		
		if (__currentShader != null) {
			
			if (__currentShader.__colorMultiplier != null) __currentShader.__colorMultiplier.__useArray = true;
			if (__currentShader.__colorOffset != null) __currentShader.__colorOffset.__useArray = true;
			
		}
		
	}
	
	
	private override function __clear ():Void {
		
		if (__stage.__transparent) {
			
			gl.clearColor (0, 0, 0, 0);
			
		} else {
			
			gl.clearColor (__stage.__colorSplit[0], __stage.__colorSplit[1], __stage.__colorSplit[2], 1);
			
		}
		
		gl.clear (gl.COLOR_BUFFER_BIT);
		
	}
	
	
	private function __clearShader ():Void {
		
		if (__currentShader != null) {
			
			if (__currentShaderBuffer == null) {
				
				if (__currentShader.__bitmap != null) __currentShader.__bitmap.input = null;
				
			} else {
				
				__currentShaderBuffer.clearOverride ();
				
			}
			
			if (__currentShader.__texture != null) __currentShader.__texture.input = null;
			if (__currentShader.__hasColorTransform != null) __currentShader.__hasColorTransform.value = null;
			if (__currentShader.__position != null) __currentShader.__position.value = null;
			if (__currentShader.__matrix != null) __currentShader.__matrix.value = null;
			__currentShader.__clearUseArray ();
			
		}
		
	}
	
	
	private function __copyShader (other:OpenGLRenderer):Void {
		
		__currentShader = other.__currentShader;
		__currentShaderBuffer = other.__currentShaderBuffer;
		__currentDisplayShader = other.__currentDisplayShader;
		__currentGraphicsShader = other.__currentGraphicsShader;
		
	}
	
	
	private function __getMatrix (transform:Matrix):Array<Float> {
		
		var _matrix = Matrix.__pool.get ();
		_matrix.copyFrom (transform);
		_matrix.concat (__worldTransform);
		
		if (__roundPixels) {
			
			_matrix.tx = Math.round (_matrix.tx);
			_matrix.ty = Math.round (_matrix.ty);
			
		}
		
		__matrix.identity ();
		__matrix[0] = _matrix.a;
		__matrix[1] = _matrix.b;
		__matrix[4] = _matrix.c;
		__matrix[5] = _matrix.d;
		__matrix[12] = _matrix.tx;
		__matrix[13] = _matrix.ty;
		__matrix.append (__flipped ? __projectionFlipped : __projection);
		
		for (i in 0...16) {
			
			__values[i] = __matrix[i];
			
		}
		
		Matrix.__pool.release (_matrix);
		
		return __values;
		
	}
	
	
	private function __initShader (shader:Shader):Shader {
		
		if (shader != null) {
			
			// TODO: Change of GL context?
			
			if (shader.gl == null) {
				
				shader.gl = gl;
				shader.__init ();
				
			}
			
			//currentShader = shader;
			return shader;
			
		}
		
		return __defaultShader;
		
	}
	
	
	private function __initDisplayShader (shader:Shader):Shader {
		
		if (shader != null) {
			
			// TODO: Change of GL context?
			
			if (shader.gl == null) {
				
				shader.gl = gl;
				shader.__init ();
				
			}
			
			//currentShader = shader;
			return shader;
			
		}
		
		return __defaultDisplayShader;
		
	}
	
	
	private function __initGraphicsShader (shader:Shader):Shader {
		
		if (shader != null) {
			
			// TODO: Change of GL context?
			
			if (shader.gl == null) {
				
				shader.gl = gl;
				shader.__init ();
				
			}
			
			//currentShader = shader;
			return shader;
			
		}
		
		return __defaultGraphicsShader;
		
	}
	
	
	private function __initShaderBuffer (shaderBuffer:ShaderBuffer):Shader {
		
		if (shaderBuffer != null) {
			
			return __initGraphicsShader (shaderBuffer.shader);
			
		}
		
		return __defaultGraphicsShader;
		
	}
	
	
	private function __getRenderTarget (framebuffer:Bool):Void {
		
		if (framebuffer) {
			
			if (__renderTargetA == null) {
				
				__renderTargetA = BitmapData.fromTexture (__stage.stage3Ds[0].context3D.createRectangleTexture (__width, __height, BGRA, true));
				
				gl.bindTexture (gl.TEXTURE_2D, __renderTargetA.getTexture (gl));
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				
			}
			
			if (__renderTargetB == null) {
				
				__renderTargetB = BitmapData.fromTexture (__stage.stage3Ds[0].context3D.createRectangleTexture (__width, __height, BGRA, true));
				
				gl.bindTexture (gl.TEXTURE_2D, __renderTargetB.getTexture (gl));
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				
			}
			
			if (__currentRenderTarget == __renderTargetA) {
				
				__currentRenderTarget = __renderTargetB;
				
			} else {
				
				__currentRenderTarget = __renderTargetA;
				
			}
			
			gl.bindFramebuffer (gl.FRAMEBUFFER, __currentRenderTarget.__getFramebuffer (gl));
			gl.viewport (0, 0, __width, __height);
			gl.clearColor (0, 0, 0, 0);
			gl.clear (gl.COLOR_BUFFER_BIT);
			
			__flipped = false;
			
		} else {
			
			__currentRenderTarget = __defaultRenderTarget;
			var frameBuffer:GLFramebuffer = (__currentRenderTarget != null) ? __currentRenderTarget.__getFramebuffer (gl) : null;
			
			gl.bindFramebuffer (gl.FRAMEBUFFER, frameBuffer);
			
			__flipped = (__currentRenderTarget == null);
			
		}
		
	}
	
	
	private override function __popMask ():Void {
		
		if (__stencilReference == 0) return;
		
		if (__stencilReference > 1) {
			
			gl.stencilOp (gl.KEEP, gl.KEEP, gl.DECR);
			gl.stencilFunc (gl.EQUAL, __stencilReference, 0xFF);
			gl.colorMask (false, false, false, false);
			
			var mask = __maskObjects.pop ();
			mask.__renderGLMask (this);
			__stencilReference--;
			
			gl.stencilOp (gl.KEEP, gl.KEEP, gl.KEEP);
			gl.stencilFunc (gl.EQUAL, __stencilReference, 0xFF);
			gl.colorMask (true, true, true, true);
			
		} else {
			
			__stencilReference = 0;
			gl.disable (gl.STENCIL_TEST);
			
		}
		
	}
	
	
	private override function __popMaskObject (object:DisplayObject, handleScrollRect:Bool = true):Void {
		
		if (object.__mask != null) {
			
			__popMask ();
			
		}
		
		if (handleScrollRect && object.__scrollRect != null) {
			
			__popMaskRect ();
			
		}
		
	}
	
	
	private override function __popMaskRect ():Void {
		
		if (__numClipRects > 0) {
			
			__numClipRects--;
			
			if (__numClipRects > 0) {
				
				__scissorRect (__clipRects[__numClipRects - 1]);
				
			} else {
				
				__scissorRect ();
				
			}
			
		}
		
	}
	
	
	private override function __pushMask (mask:DisplayObject):Void {
		
		if (__stencilReference == 0) {
			
			gl.enable (gl.STENCIL_TEST);
			gl.stencilMask (0xFF);
			gl.clear (gl.STENCIL_BUFFER_BIT);
			
		}
		
		gl.stencilOp (gl.KEEP, gl.KEEP, gl.INCR);
		gl.stencilFunc (gl.EQUAL, __stencilReference, 0xFF);
		gl.colorMask (false, false, false, false);
		
		mask.__renderGLMask (this);
		__maskObjects.push (mask);
		__stencilReference++;
		
		gl.stencilOp (gl.KEEP, gl.KEEP, gl.KEEP);
		gl.stencilFunc (gl.EQUAL, __stencilReference, 0xFF);
		gl.colorMask (true, true, true, true);
		
	}
	
	
	private override function __pushMaskObject (object:DisplayObject, handleScrollRect:Bool = true):Void {
		
		if (handleScrollRect && object.__scrollRect != null) {
			
			__pushMaskRect (object.__scrollRect, object.__renderTransform);
			
		}
		
		if (object.__mask != null) {
			
			__pushMask (object.__mask);
			
		}
		
	}
	
	
	private override function __pushMaskRect (rect:Rectangle, transform:Matrix):Void {
		
		// TODO: Handle rotation?
		
		if (__numClipRects == __clipRects.length) {
			
			__clipRects[__numClipRects] = new Rectangle ();
			
		}
		
		var clipRect = __clipRects[__numClipRects];
		rect.__transform (clipRect, transform);
		
		if (__numClipRects > 0) {
			
			var parentClipRect = __clipRects[__numClipRects - 1];
			clipRect.__contract (parentClipRect.x, parentClipRect.y, parentClipRect.width, parentClipRect.height);
			
		}
		
		if (clipRect.height < 0) {
			
			clipRect.height = 0;
			
		}
		
		if (clipRect.width < 0) {
			
			clipRect.width = 0;
			
		}
		
		__scissorRect (clipRect);
		__numClipRects++;
		
	}
	
	
	private override function __render (object:IBitmapDrawable):Void {
		
		if (__defaultRenderTarget == null) {
			
			gl.viewport (__offsetX, __offsetY, __displayWidth, __displayHeight);
			
			__upscaled = (__worldTransform.a != 1 || __worldTransform.d != 1);
			
			object.__renderGL (this);
			
			if (__offsetX > 0 || __offsetY > 0) {
				
				gl.clearColor (0, 0, 0, 1);
				gl.enable (gl.SCISSOR_TEST);
				
				if (__offsetX > 0) {
					
					gl.scissor (0, 0, __offsetX, __height);
					gl.clear (gl.COLOR_BUFFER_BIT);
					
					gl.scissor (__offsetX + __displayWidth, 0, __width, __height);
					gl.clear (gl.COLOR_BUFFER_BIT);
					
				}
				
				if (__offsetY > 0) {
					
					gl.scissor (0, 0, __width, __offsetY);
					gl.clear (gl.COLOR_BUFFER_BIT);
					
					gl.scissor (0, __offsetY + __displayHeight, __width, __height);
					gl.clear (gl.COLOR_BUFFER_BIT);
					
				}
				
				gl.disable (gl.SCISSOR_TEST);
				
			}
			
		} else {
			
			gl.viewport (__offsetX, __offsetY, __displayWidth, __displayHeight);
			
			// __upscaled = (__worldTransform.a != 1 || __worldTransform.d != 1);
			
			object.__renderGL (this);
			
		}
		
	}
	
	
	private function __renderFilterPass (source:BitmapData, shader:Shader):Void {
		
		if (source == null || shader == null) return;
		if (__defaultRenderTarget == null) return;
		
		gl.bindFramebuffer (gl.FRAMEBUFFER, __defaultRenderTarget.__getFramebuffer (gl));
		
		gl.clearColor (0, 0, 0, 0);
		gl.clear (gl.COLOR_BUFFER_BIT);
		
		var shader = __initShader (shader);
		setShader (shader);
		applyAlpha (1);
		applyBitmapData (source, false);
		applyColorTransform (null);
		applyMatrix (__getMatrix (source.__renderTransform));
		updateShader ();
		
		gl.bindBuffer (gl.ARRAY_BUFFER, source.getBuffer (gl));
		if (shader.__position != null) gl.vertexAttribPointer (shader.__position.index, 3, gl.FLOAT, false, 14 * Float32Array.BYTES_PER_ELEMENT, 0);
		if (shader.__texCoord != null) gl.vertexAttribPointer (shader.__texCoord.index, 2, gl.FLOAT, false, 14 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
		gl.drawArrays (gl.TRIANGLE_STRIP, 0, 4);
		
		gl.bindFramebuffer (gl.FRAMEBUFFER, null);
		
		__clearShader ();
		
	}
	
	
	private override function __renderStage3D (stage:Stage):Void {
		
		for (stage3D in stage.stage3Ds) {
			
			stage3D.__renderGL (stage, this);
			
		}
		
	}
	
	
	private override function __resize (width:Int, height:Int):Void {
		
		__width = width;
		__height = height;
		
		// if (cacheObject == null || cacheObject.width != width || cacheObject.height != height) {
			
		// 	cacheObject = BitmapData.fromTexture (stage.stage3Ds[0].context3D.createRectangleTexture (width, height, BGRA, true));
			
		// 	gl.bindTexture (gl.TEXTURE_2D, cacheObject.getTexture (gl));
		// 	gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		// 	gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
			
		// }
		
		if (__width > 0 && __height > 0) {
			
			if (__renderTargetA != null && (__renderTargetA.width != __width || __renderTargetA.height != __height)) {
				
				__renderTargetA = BitmapData.fromTexture (__stage.stage3Ds[0].context3D.createRectangleTexture (__width, __height, BGRA, true));
				
				gl.bindTexture (gl.TEXTURE_2D, __renderTargetA.getTexture (gl));
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				
			}
			
			if (__renderTargetB != null && (__renderTargetB.width != __width || __renderTargetB.height != __height)) {
				
				__renderTargetB = BitmapData.fromTexture (__stage.stage3Ds[0].context3D.createRectangleTexture (__width, __height, BGRA, true));
				
				gl.bindTexture (gl.TEXTURE_2D, __renderTargetB.getTexture (gl));
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				
			}
			
		}
		
		// displayMatrix = (defaultRenderTarget == null) ? stage.__displayMatrix : new Matrix ();
		
		var w = (__defaultRenderTarget == null) ? __stage.stageWidth : __defaultRenderTarget.width;
		var h = (__defaultRenderTarget == null) ? __stage.stageHeight : __defaultRenderTarget.height;
		
		__offsetX = __defaultRenderTarget == null ? Math.round (__worldTransform.__transformX (0, 0)) : 0;
		__offsetY = __defaultRenderTarget == null ? Math.round (__worldTransform.__transformY (0, 0)) : 0;
		__displayWidth = __defaultRenderTarget == null ? Math.round (__worldTransform.__transformX (w, 0) - __offsetX) : w;
		__displayHeight = __defaultRenderTarget == null ? Math.round (__worldTransform.__transformY (0, h) - __offsetY) : h;
		
		__projection = Matrix4.createOrtho (__offsetX, __displayWidth + __offsetX, __offsetY, __displayHeight + __offsetY, -1000, 1000);
		__projectionFlipped = Matrix4.createOrtho (__offsetX, __displayWidth + __offsetX, __displayHeight + __offsetY, __offsetY, -1000, 1000);
		
	}
	
	
	private function __scissorRect (rect:Rectangle = null):Void {
		
		if (rect != null) {
			
			gl.enable (gl.SCISSOR_TEST);
			
			var clipRect = __tempRect;
			rect.__transform (clipRect, __worldTransform);
			
			var x = Math.floor (clipRect.x);
			var y = Math.floor (__height - clipRect.y - clipRect.height);
			var width = Math.ceil (clipRect.width);
			var height = Math.ceil (clipRect.height);
			
			if (width < 0) width = 0;
			if (height < 0) height = 0;
			
			gl.scissor (x, y, width, height);
			
		} else {
			
			gl.disable (gl.SCISSOR_TEST);
			
		}
		
	}
	
	
	private override function __setBlendMode (value:BlendMode):Void {
		
		if (__blendMode == value) return;
		
		__blendMode = value;
		
		switch (value) {
			
			case ADD:
				
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE);
			
			case MULTIPLY:
				
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA);
			
			case SCREEN:
				
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE_MINUS_SRC_COLOR);
			
			case SUBTRACT:
				
				gl.blendEquation (gl.FUNC_REVERSE_SUBTRACT);
				gl.blendFunc (gl.ONE, gl.ONE);
			
			#if desktop
			case DARKEN:
				
				gl.blendEquation (0x8007); // GL_MIN
				gl.blendFunc (gl.ONE, gl.ONE);
				
			case LIGHTEN:
				
				gl.blendEquation (0x8008); // GL_MAX
				gl.blendFunc (gl.ONE, gl.ONE);
			#end
			
			default:
				
				gl.blendEquation (gl.FUNC_ADD);
				gl.blendFunc (gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
			
		}
		
	}
	
	
	private function __setRenderTarget (renderTarget:BitmapData):Void {
		
		__defaultRenderTarget = renderTarget;
		__flipped = (renderTarget == null);
		
		if (renderTarget != null) {
			
			__resize (renderTarget.width, renderTarget.height);
			
		}
		
	}
	
	
	private function __setShaderBuffer (shaderBuffer:ShaderBuffer):Void {
		
		setShader (shaderBuffer.shader);
		__currentShaderBuffer = shaderBuffer;
		
	}
	
	
	private function __updateShaderBuffer ():Void {
		
		if (__currentShader != null && __currentShaderBuffer != null) {
			
			__currentShader.__updateFromBuffer (__currentShaderBuffer);
			
		}
		
	}
	
	
}