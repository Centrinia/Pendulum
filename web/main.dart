import 'dart:math';
import 'dart:html';
import 'dart:async';

class Renderer {
  static const TICS_PER_SECOND = 30;
  static const PENDULUMS = 30;
  static const GRAVITY = 9.8;
  CanvasElement _canvas;
  CanvasRenderingContext2D _context;

  static const START_LENGTH = 0.5;
  static const END_LENGTH = 1.0;
  List<double> _pendulumLengths;
  double _currentTime;

  double _startLength;
  double _endLength;
  
  set startLength(double val) {
    setLengths(val, _endLength);
  }
  get startLength => _startLength;
  
  set endLength(double val) {
    setLengths(_startLength,val);
  }
  get endLength => _endLength;
  
  void setLengths(double start, double end){
    for (int i = 0; i < _pendulumLengths.length; i++) {
      double t = i / (_pendulumLengths.length - 1.0);
      _pendulumLengths[i] = (1 - t) * start + t * end;
    }
    _startLength = start;
    _endLength = end;
    
  }
  Renderer(CanvasElement canvas) {
    _canvas = canvas;
    _context = _canvas.context2D;
    _pendulumLengths = new List<double>(10);

    setLengths(0.5,1.0);
    _currentTime = 0.0;
  }
  static double _pendulumAngle(double t, double l, double starting) {
    double period = sqrt(GRAVITY / l);
    return starting * cos(period * t);
  }

  void reset(){
    _currentTime = 0.0;
  }
  void render() {
    double radius = 1.0 / (4.0 * _pendulumLengths.length);
    _context.save();
    _context.scale(_canvas.width, _canvas.height);
    _context.clearRect(0, 0, 1, 1);
    
    _context.lineWidth = 2/_canvas.width;
    _context.beginPath();
    _context.moveTo(0.5, 0.0);
    _context.lineTo(0.5, 1.0);
    _context.stroke();
    _context.lineWidth = 0.03;

    for (int i = 0; i < _pendulumLengths.length; i++) {
      double y = (1 + i) / (_pendulumLengths.length + 2);
      double pendulumLength = _pendulumLengths[i];
      double theta = _pendulumAngle(_currentTime, pendulumLength, PI/8);
      double x = (sin(theta)+1.0)/2.0;
      _context.beginPath();
      _context.arc(x, y, radius, 0, 2 * PI);
      _context.stroke();
    }
    _context.restore();
  }
  void loop(Timer timer) {
    if(_currentTime != null){
    render();
    _currentTime += 1.0 / TICS_PER_SECOND;
    }
  }
  Timer startTimer() {
    const duration = const Duration(milliseconds: 1000 ~/ TICS_PER_SECOND);

    return new Timer.periodic(duration, loop);
  }
}
void main() {
  CanvasElement selection = querySelector("#screen");
  Renderer renderer = new Renderer(selection);
  {
    void changeValue(String elementName, Function valueChanger,
        Function getValue, double defaultValue) {
      InputElement valueElement = querySelector(elementName) as InputElement;
      valueElement.onChange.listen((Event onData) {
        try {
          valueChanger(renderer, double.parse(valueElement.value));
          renderer.reset();
        } catch (e) {}
      });
      valueElement.onMouseWheel.listen((WheelEvent e) {
        const increment = 1.1;
        const scale = 200.0;
        double v = getValue(renderer);
        v *= pow(increment, -e.deltaY / scale);
        valueChanger(renderer, v);
        renderer.reset();
        valueElement.value = v.toString();
      });

      valueElement.value = defaultValue.toString();
      valueChanger(renderer, defaultValue);
    }

    changeValue("#startLength", (r, v) => r.startLength = v,
        (r) => r.startLength, 0.5);
    changeValue("#endLength", (r, v) => r.endLength = v,
        (r) => r.endLength, 1.0);

  }
  querySelector('#resetButton').onClick.listen((MouseEvent e) {
    renderer.reset();
  });
  
  renderer.startTimer();
}
