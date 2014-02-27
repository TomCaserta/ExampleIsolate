import 'dart:html';
import 'dart:async';
import 'dart:isolate';


/***
 * Creates an isolate from the [processUrl]
 * [fromStream] should be a stream of dart2js supported isolate messages.
 * 
 * Returns a stream of response data from the isolate.
 */
Stream processStream (String processUrl, Stream fromStream) {
 StreamController responseStream = new StreamController();
 ReceivePort receivePort = new ReceivePort();
 
 // Spawn our isolate with the main threads send port
 Isolate.spawnUri(Uri.parse(processUrl), [], receivePort.sendPort);
 // We want the first message to be a "handshake" of sorts.
 bool isFirstMessage = true;
 receivePort.listen((dynamic response) {
    if (isFirstMessage && response is SendPort) {
      // Send our stream data to the isolate...
      fromStream.listen((data) => response.send(data));
    }
    else if (isFirstMessage) {
      throw new Exception("Expected first isolate message to be a SendPort");
    }
    else {
      // Anything else is the response of the isolate (ie. actual processed data)...
      responseStream.add(response);
    }        
    isFirstMessage = false;
 }, onDone: () => responseStream.close());
  // We do not need to check for errors as receive ports will never receive errors.
 
 return responseStream.stream;
}


// Example usage:
void main() {
  StreamController sc = new StreamController();
  
  TextAreaElement tae = querySelector("#output");
  void output (val)  {
    tae.value = "${tae.value}\n${val.toString()}"; 
  }
  
  ButtonElement spawnIsolate = querySelector("#spawn-isolate");
  spawnIsolate.onClick.listen((_) {
      Stream outputStream = processStream("isolate.dart", sc.stream);
      spawnIsolate.disabled = true;
      output("Spawned isolate!");
      outputStream.listen((data) { 
        output(data.toString());
      });
  });
  
  ButtonElement sendNumeric = querySelector("#send-numeric");
  InputElement numeric = querySelector("#numeric");
  sendNumeric.onClick.listen((_) { 
     int parsedNum = int.parse(numeric.value, onError: (s) { output("Could not parse $s as integer, using 0 instead"); return 0; });
     sc.add(parsedNum);
  });
  
}
