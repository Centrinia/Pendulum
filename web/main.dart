import 'dart:math';
import 'dart:html';
import 'dart:async';

class Renderer {
  static const PENDULUM_SPAN = 0.65;
  static const TICS_PER_SECOND = 60;
  static const PENDULUMS = 15;
  static const GRAVITY = 9.8;
  CanvasElement _canvas;
  CanvasRenderingContext2D _context;
  CanvasElement _vcanvas;
  CanvasRenderingContext2D _vcontext;

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
  Renderer(CanvasElement canvas, CanvasElement vcanvas) {
    _canvas = canvas;
    _context = _canvas.context2D;

    _vcanvas = vcanvas;
    _vcontext = _vcanvas.context2D;

    _pendulumLengths = new List<double>(PENDULUMS);

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

    _vcontext.save();
    _vcontext.scale(_vcanvas.width, _vcanvas.height);
    _vcontext.clearRect(0, 0, 1, 1);

    _context.lineWidth = 2/_canvas.width;
    _context.beginPath();
    _context.moveTo(0.5, 0.0);
    _context.lineTo(0.5, 1.0);
    _context.stroke();


    
    double maxLength = max(_pendulumLengths.first, _pendulumLengths.last);
    for (int i = 0; i < _pendulumLengths.length; i++) {
      double y = (1 + i) / (_pendulumLengths.length + 2);
      double pendulumLength = _pendulumLengths[i];
      double theta = _pendulumAngle(_currentTime, pendulumLength, PI/4);
      double x = PENDULUM_SPAN*sin(theta)*pendulumLength/maxLength+0.5;
      double vy = PENDULUM_SPAN*cos(theta)*pendulumLength/maxLength;
      _context.lineWidth = 0.03;
      _context.beginPath();
      _context.arc(x, y, radius, 0, 2 * PI);
      _context.stroke();
      _context.lineWidth = 1/_canvas.width;
      _context.beginPath();
      _context.moveTo(0.5,y+radius/2);
      _context.lineTo(x, y);
      _context.stroke();
      _context.beginPath();
      _context.moveTo(0.5,y-radius/2);
      _context.lineTo(x, y);
      _context.stroke();

      _vcontext.lineWidth = 2/_canvas.width;

      _vcontext.beginPath();
      _vcontext.moveTo(0.5, 0);
      _vcontext.lineTo(x, vy);
       _vcontext.stroke();

      _vcontext.lineWidth = 0.03;

      _vcontext.beginPath();
      _vcontext.arc(x, vy, radius, 0, 2*PI);
      _vcontext.stroke();
    }
    _vcontext.restore();
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
  Renderer renderer = new Renderer( querySelector("#screen"),  querySelector("#vscreen"));
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
        (r) => r.startLength, 0.21862);
    changeValue("#endLength", (r, v) => r.endLength = v,
        (r) => r.endLength, 0.34427);

  }
  querySelector('#resetButton').onClick.listen((MouseEvent e) {
    renderer.reset();
  });
  
  renderer.startTimer();
}
