import haxe.io.Bytes;
import haxe.io.Float32Array;
import hl.Format;
import sdl.GL;
import sdl.Sdl;
import sdl.Window;
import sys.io.File;


final VERTEX_SHADER:String = '
#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
';
final FRAGMENT_SHADER:String = '
#version 330 core
out vec4 FragColor;
void main()
{
   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
';



final WINDOW_WIDTH = 800;
final WINDOW_HEIGHT = 600;

function main() {
	Sdl.init();

	final window = new Window('Haxe 0.0.1', WINDOW_WIDTH, WINDOW_HEIGHT);
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
		if (log.length > 0) { throw log; }
		return shader;
	}

	final shaderProgram = GL.createProgram();
	GL.attachShader(shaderProgram, compileShader(VERTEX_SHADER, GL.VERTEX_SHADER));
	GL.attachShader(shaderProgram, compileShader(FRAGMENT_SHADER, GL.FRAGMENT_SHADER));
	GL.linkProgram(shaderProgram);

	final log = GL.getProgramInfoLog(shaderProgram);
	if (log.length > 0) { throw log; }

	// GL.useProgram(shaderProgram);

	final vertecies = Float32Array.fromArray([
	   -0.5, -0.5, 0.0,
		0.5, -0.5, 0.0,
		0.0,  0.5, 0.0
	]).getData();


	final vbo = GL.createBuffer();
	final vao = GL.createVertexArray();
    GL.bindVertexArray(vao);

    GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
    GL.bufferData(GL.ARRAY_BUFFER, vertecies.byteLength, hl.Bytes.fromBytes(vertecies.bytes), GL.STATIC_DRAW);

	// 3 * sizeof(float)
	trace("Hello World: " + vertecies.byteLength);
  
  // The byte of Float32Array is 4 
	GL.vertexAttribPointer(0, 3, GL.FLOAT, false, 3 * 4, 0);
	GL.enableVertexAttribArray(0);

	GL.bindBuffer(GL.ARRAY_BUFFER, vbo); 
	GL.bindVertexArray(vao); 

	/*
	GL.bindBuffer(GL.ARRAY_BUFFER, vbo);		
	GL.bufferData(GL.ARRAY_BUFFER, vertecies.byteLength, hl.Bytes.fromBytes(vertecies.bytes), GL.STATIC_DRAW);
	GL.bindVertexArray(vao);
	*/

	GL.enable(GL.BLEND);
	GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
	GL.viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
	
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
		GL.clearColor(40/255, 40/255, 40/255, 255/255);
		GL.clear(GL.COLOR_BUFFER_BIT);
		GL.useProgram(shaderProgram);
		GL.bindVertexArray(vao); 
		GL.drawArrays(GL.TRIANGLES, 0, 3);
		window.present();
	}
	window.destroy();
	Sdl.quit();
}
