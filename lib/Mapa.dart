import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class Mapa extends StatefulWidget {
  const Mapa({Key? key}) : super(key: key);

  @override
  State<Mapa> createState() => _MapaState();
}

class _MapaState extends State<Mapa> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _marcadores = {};
  CameraPosition _posicaoCamera = const CameraPosition(
      target: LatLng(-23.00194274577608, -43.366454296951616), zoom: 14);

  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _exibirMarcador(LatLng latLng) async {
    //List<Placemark> listaEnderecos = Geolocator.getCurrentPosition()

    Marker marcador = Marker(
        markerId: MarkerId("marcador-$latLng.latitude-$latLng.longitude"),
        position: latLng,
        infoWindow: const InfoWindow(title: "Marcador"));
    setState(() {
      _marcadores.add(marcador);
    });
  }

  _movimentarCamera() async {
    //metodo que movimenta a camera conforme a posição
    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(_posicaoCamera),
    );
  }

  _adicionarListenerLocalizacao() {
    var locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 3),
    );
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      //passa a posicao atual para a camera
      setState(() {
        _posicaoCamera = CameraPosition(
            target: LatLng(position!.latitude, position.longitude), zoom: 17);
        //movimenta a camera conforme a posição
        _movimentarCamera();
      });
    });
  }

  _recuperarLocalizacaoAtual() async {
    Position position = await _determinePosirion();
    print("Localização atual: $position");
  }

  Future<Position> _determinePosirion() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission are danied');
      }
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  _recuperarLocalParaEndereco() async {
    List<Location> listaEnderecos =
        await locationFromAddress("Av. Paulista, 1372");
    //print("toral:${listaEnderecos.length}");

    if (listaEnderecos.isNotEmpty) {
      Location endereco = listaEnderecos[0];
      List<Placemark> placemark =
          await placemarkFromCoordinates(endereco.latitude, endereco.longitude);
      Placemark place = placemark[0];
      String resultado = '';

      //resultado = place.country.toString();
      //resultado = place.street.toString();
      resultado = place.administrativeArea.toString();

      print("area: $resultado");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //_recuperarLocalizacaoAtual();
    //_adicionarListenerLocalizacao(); // monitora a localização do usuario
    _recuperarLocalParaEndereco();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: Container(
        child: GoogleMap(
          markers: _marcadores,
          mapType: MapType.normal,
          initialCameraPosition: _posicaoCamera,
          onMapCreated: _onMapCreated,
          onLongPress: _exibirMarcador,
          myLocationEnabled: true,
        ),
      ),
    );
  }
}
