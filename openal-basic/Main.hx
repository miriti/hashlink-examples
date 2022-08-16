import format.wav.Reader;
import haxe.io.Bytes;
import openal.AL;
import openal.ALC;
import sys.io.File;

function main() {
	// Check for enumeration extension
	if (ALC.isExtensionPresent(null, hl.Bytes.fromBytes(Bytes.ofString("ALC_ENUMERATION_EXT")))) {
		/*
			Get devices list string data.

			Each device name is separated by a null character
			The list is terminated by two null characters
		**/

		final bytes = ALC.getString(null, ALC.DEVICE_SPECIFIER);

		final devices:Array<String> = [];

		// Start character position of the next device name in the device list string
		var from = 0;
		// End character position of the device name
		var to = 0;

		while (true) {
			final char = bytes.getUI8(to);

			if (char == 0) {
				if (from == to)
					break;

				final len = to - from;
				final deviceName = bytes.sub(from, len).toBytes(len).toString();
				devices.push(deviceName);
				from = to + 1;
			}

			to++;
		}

		Sys.println('Devices (${devices.length}):');
		for (name in devices)
			Sys.println('  $name');
	} else {
		Sys.println('Device enumeration is not supported');
	}

	// Open the default device
	final device = ALC.openDevice(null);

	// Create a context from the opened device
	final context = ALC.createContext(device, null);

	// Make the created context current
	if (!ALC.makeContextCurrent(context))
		throw ALC.getError(device);

	// Allocate 4 bytes to store generated source ID (int32)
	final srcBytes = Bytes.alloc(4);

	// Generate a source - its ID will be stored in the provided Bytes
	AL.genSources(1, srcBytes);

	final source = Source.ofInt(srcBytes.getInt32(0));

	// Load a WAV file
	final wavData = new Reader(File.read('music.wav')).read();

	// Infere OpenAL format from the WAV data
	final format:Int = switch (wavData.header.channels) {
		case 1:
			switch (wavData.header.bitsPerSample) {
				case 8:
					AL.FORMAT_MONO8;
				case 16:
					AL.FORMAT_MONO16;
				case _:
					-1;
			}
		case 2:
			switch (wavData.header.bitsPerSample) {
				case 8:
					AL.FORMAT_STEREO8;
				case 16:
					AL.FORMAT_STEREO16;
				case _:
					-1;
			}
		case _:
			-1;
	}

	if (format == -1)
		throw 'Unsupported WAV format (BPS: ${wavData.header.bitsPerSample}, Channels: ${wavData.header.channels})';

	// Generate a buffer
	final bufBytes = Bytes.alloc(4);
	AL.genBuffers(1, bufBytes);

	final buffer = Buffer.ofInt(bufBytes.getInt32(0));

	// Load WAV data into the newly created buffer
	AL.bufferData(buffer, format, hl.Bytes.fromBytes(wavData.data), wavData.data.length, wavData.header.samplingRate);

	// Connect the buffer to the source
	AL.sourcei(source, AL.BUFFER, buffer.toInt());

	// Play source. This method is asynchronous - the playback is running in a separate thread so the call returns immideately.
	AL.sourcePlay(source);

	// Loop while the source is playing and display playing position in the terminal
	while (AL.getSourcei(source, AL.SOURCE_STATE) == AL.PLAYING) {
		Sys.print('Position ${AL.getSourcef(source, AL.SEC_OFFSET)}s\r');
		Sys.sleep(0.016);
	}

	Sys.println('');

	/*
		Clean-up
	 */
	AL.deleteSources(1, srcBytes);
	AL.deleteBuffers(1, bufBytes);
	ALC.makeContextCurrent(null);
	ALC.destroyContext(context);
	ALC.closeDevice(device);
}
