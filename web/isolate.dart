import 'dart:isolate';

// Example isolate just takes int values and outputs the value + 1

void main (List args, dynamic mainThread) {
  if (mainThread is SendPort) {
    ReceivePort receivePort = new ReceivePort();
    // Handshake!
    mainThread.send(receivePort.sendPort);
    
    receivePort.listen((data) { 
      // [data] is our stream data
      if (data is int) {
        mainThread.send(data + 1);
      }
    });
  }
  else throw new Exception("Expected value to be a 'SendPort'");
}
