import 'package:example/features/me/bloc/me_bloc.dart';
import 'package:example/features/media_devices/bloc/media_devices_bloc.dart';
import 'package:example/features/producers/bloc/producers_bloc.dart';
import 'package:example/features/signaling/room_client_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Webcam extends StatelessWidget {
  const Webcam({super.key});

  @override
  Widget build(BuildContext context) {
    final videoInputDevicesLength = context.select(
      (MediaDevicesBloc bloc) => bloc.state.videoInputs.length,
    );
    final inProgress = context.select(
      (MeBloc bloc) => bloc.state.webcamInProgress,
    );
    final webcam = context.select((ProducersBloc bloc) => bloc.state.webcam);
    if (videoInputDevicesLength == 0) {
      return IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.videocam,
          color: Colors.grey,
          // size: screenHeight * 0.045,
        ),
      );
    }
    if (webcam == null) {
      return ElevatedButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(const CircleBorder()),
          padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
          backgroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) return Colors.grey;
            return null;
          }),
          shadowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) return Colors.grey;
            return null;
          }),
        ),
        onPressed: () {
          if (!inProgress) {
            context.read<RoomClientRepository>().enableWebcam();
          }
        },
        child: const Icon(
          Icons.videocam_off,
          color: Colors.black,
          // size: screenHeight * 0.045,
        ),
      );
    }
    return ElevatedButton(
      style: ButtonStyle(
        shape: WidgetStateProperty.all(const CircleBorder()),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        backgroundColor: WidgetStateProperty.all(Colors.white),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) return Colors.grey;
          return null;
        }),
        shadowColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) return Colors.grey;
          return null;
        }),
      ),
      onPressed: () {
        if (!inProgress) {
          context.read<RoomClientRepository>().disableWebcam();
        }
      },
      child: const Icon(
        Icons.videocam,
        color: Colors.black,
        // size: screenHeight * 0.045,
      ),
    );
  }
}
