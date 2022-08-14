import haxe.io.Bytes;
import haxe.io.Float32Array;
import hl.Format;
import sdl.GL;
import sdl.Sdl;
import sdl.Window;
import sys.io.File;

final VERTEX_SHADER:String = '#version 150

in vec2 inPos;
in vec2 inTexCoord;

out vec2 texCoord;

void main()
{
    gl_Position = vec4(inPos, 0.0f, 1.0f);
	texCoord = inTexCoord;
}';
final FRAGMENT_SHADER:String = '#version 150

in vec2 texCoord;
out vec4 fragColor;

uniform sampler2D uTexture;

void main()
{
    fragColor = texture(uTexture, texCoord);
}';
final WINDOW_WIDTH = 600;
final WINDOW_HEIGHT = 600;

function main() {
	Sdl.init();

	final window = new Window('HashLink SDL', WINDOW_WIDTH, WINDOW_HEIGHT);
	window.vsync = true;

	if (!GL.init()) {
		trace('GL.init() failed');
		return;
	}

	window.title += ' OpenGL ${GL.getParameter(GL.VERSION)}';

	function compileShader(code:String, type:Int) {
		final shader = GL.createShader(type);
		GL.shaderSource(shader, code);
		GL.compileShader(shader);

		final log = GL.getShaderInfoLog(shader);

		if (log.length > 0)
			throw log;

		return shader;
	}

	final shaderProgram = GL.createProgram();
	GL.attachShader(shaderProgram, compileShader(VERTEX_SHADER, GL.VERTEX_SHADER));
	GL.attachShader(shaderProgram, compileShader(FRAGMENT_SHADER, GL.FRAGMENT_SHADER));
	GL.linkProgram(shaderProgram);

	final posAttrib = GL.getAttribLocation(shaderProgram, 'inPos');
	final texAttrib = GL.getAttribLocation(shaderProgram, 'inTexCoord');

	final log = GL.getProgramInfoLog(shaderProgram);

	if (log.length > 0)
		throw log;

	GL.useProgram(shaderProgram);

	/**
		x, y, u, v

		A -- C
		|  / |
		B -- D
	**/

	final vertecies = Float32Array.fromArray([
		-0.5,  0.5, 0.0, 0.0,
		-0.5, -0.5, 0.0, 1.0,
		 0.5,  0.5, 1.0, 0.0,
		 0.5, -0.5, 1.0, 1.0,
	]).getData();

	final vbo = GL.createBuffer();
	GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
	GL.bufferData(GL.ARRAY_BUFFER, vertecies.byteLength, hl.Bytes.fromBytes(vertecies.bytes), GL.STATIC_DRAW);

	final vao = GL.createVertexArray();
	GL.bindVertexArray(vao);

	GL.enableVertexAttribArray(posAttrib);
	GL.enableVertexAttribArray(texAttrib);

	GL.vertexAttribPointer(posAttrib, 2, GL.FLOAT, false, 16, 0);
	GL.vertexAttribPointer(texAttrib, 2, GL.FLOAT, false, 16, 8);

	final TEXTURE_WIDTH = 256;
	final TEXTURE_HEIGHT = 256;

	final rawPngData = File.getBytes('haxe.png');
	final pixelsData = Bytes.alloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4);

	if (!Format.decodePNG(hl.Bytes.fromBytes(rawPngData), rawPngData.length, pixelsData, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, PixelFormat.RGBA, 0))
		throw 'Failed to decode PNG data';

	final texture = GL.createTexture();
	GL.bindTexture(GL.TEXTURE_2D, texture);

	GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, GL.RGBA, GL.UNSIGNED_BYTE, hl.Bytes.fromBytes(pixelsData));
	GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

	GL.enable(GL.BLEND);
	GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

	GL.viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	GL.clearColor(0.5, 0.5, 0.5, 1.0);

	var quit = false;

	while (!quit && Sdl.processEvents((event) -> {
		switch (event.type) {
			case Quit:
				return true;
			case KeyDown:
				if (event.keyCode == 27) quit = true;
			case _:
				return false;
		}
		return false;
	})) {
		GL.clear(GL.COLOR_BUFFER_BIT);

		GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);

		window.present();
	}

	window.destroy();
	Sdl.quit();
}
