import 'package:collection/collection.dart';
import 'package:mediasoup_client_flutter/src/handlers/sdp/media_section.dart';
import 'package:mediasoup_client_flutter/src/rtp_parameters.dart';
import 'package:mediasoup_client_flutter/src/sdp_object.dart';
import 'package:mediasoup_client_flutter/src/transport.dart';
import 'package:sdp_transform/sdp_transform.dart';

class CommonUtils {
  static RtpCapabilities extractRtpCapabilities(SdpObject sdpObject) {
    // Map of RtpCodecParameters indexed by payload type.
    var codecsMap = <int, RtpCodecCapability>{};
    // Array of RtpHeaderExtensions.
    var headerExtensions = <RtpHeaderExtension>[];
    // Whether a m=audio/video section has been already found.
    var gotAudio = false;
    var gotVideo = false;

    for (final m in sdpObject.media) {
      var kind = m.type!;

      switch (kind) {
        case 'audio':
          {
            if (gotAudio) {
              continue;
            }
            gotAudio = true;
            break;
          }
        case 'video':
          {
            if (gotVideo) {
              continue;
            }
            gotVideo = true;
            break;
          }
        default:
          {
            continue;
          }
      }

      // Get codecs.
      for (final rtp in m.rtp!) {
        var codec = RtpCodecCapability(
          kind: RTCRtpMediaTypeExtension.fromString(kind),
          mimeType: '$kind/${rtp.codec}',
          preferredPayloadType: rtp.payload,
          clockRate: rtp.rate,
          channels: rtp.encoding,
          parameters: {},
          rtcpFeedback: [],
        );

        codecsMap[codec.preferredPayloadType!] = codec;
      }

      // Get codec parameters.
      for (final fmtp in m.fmtp ?? []) {
        final parameters = parseParams(fmtp.config);
        final codec = codecsMap[fmtp.payload];

        if (codec == null) {
          continue;
        }

        // Specials case to convert parameter value to string.
        if (parameters['profile-level-id'] != null) {
          parameters['profile-level-id'] = '${parameters['profile-level-id']}';
        }

        codec.parameters = parameters;
      }

      // Get RTCP feedback for each codec.
      for (final fb in m.rtcpFb ?? []) {
        var codec = codecsMap[fb.payload];

        if (codec == null) {
          continue;
        }

        var feedback = RtcpFeedback(type: fb.type, parameter: fb.subtype);

        // if (feedback.parameter == null || feedback.parameter.isEmpty) {
        //   feedback.parameter = null;
        // }

        codec.rtcpFeedback.add(feedback);
      }

      // Get RTP header extensions.
      for (final ext in m.ext ?? []) {
        // Ignore encrypted extensions (not yet supported in mediasoup).
        if (ext.encryptUri?.isNotEmpty == true) {
          continue;
        }

        var headerExtension = RtpHeaderExtension(
          kind: RTCRtpMediaTypeExtension.fromString(kind),
          uri: ext.uri,
          preferredId: ext.value,
        );

        headerExtensions.add(headerExtension);
      }
    }

    var rtpCapabilities = RtpCapabilities(
      codecs: List<RtpCodecCapability>.of(codecsMap.values),
      headerExtensions: headerExtensions,
    );

    return rtpCapabilities;
  }

  static DtlsParameters extractDtlsParameters(SdpObject sdpObject) {
    var mediaObject = sdpObject.media.firstWhereOrNull(
      (m) => m.iceUfrag != null && m.iceUfrag!.isNotEmpty && m.port != null && m.port != 0,
    );

    if (mediaObject == null) {
      throw Exception('no active media section found');
    }

    var fingerprint = (mediaObject.fingerprint ?? sdpObject.fingerprint)!;

    var role = DtlsRole.auto;

    switch (mediaObject.setup) {
      case 'active':
        role = DtlsRole.client;
        break;
      case 'passive':
        role = DtlsRole.server;
        break;
      case 'actpass':
        role = DtlsRole.auto;
        break;
    }

    var dtlsParameters = DtlsParameters(
      role: role,
      fingerprints: [DtlsFingerprint(algorithm: fingerprint.type, value: fingerprint.hash)],
    );

    return dtlsParameters;
  }

  static String getCname(MediaObject? offerMediaObject) {
    var ssrcCnameLine = (offerMediaObject?.ssrcs ?? []).firstWhere(
      (Ssrc ssrc) => ssrc.attribute == 'cname',
      orElse: () => Ssrc(value: ''),
    );

    return ssrcCnameLine.value;
  }

  /// Apply codec parameters in the given SDP m= section answer based on the
  /// given RTP parameters of an offer.
  static void applyCodecParameters(
    RtpParameters offerRtpParameters,
    MediaObject? answerMediaObject,
  ) {
    for (final codec in offerRtpParameters.codecs) {
      var mimeType = codec.mimeType.toLowerCase();

      // Avoid parsing codec parameters for unhandled codecs.
      if (mimeType != 'audio/opus') {
        continue;
      }

      var rtp = (answerMediaObject?.rtp ?? []).firstWhereOrNull(
        (Rtp r) => r.payload == codec.payloadType,
      );

      if (rtp == null) {
        continue;
      }

      // Just in case.. ?
      answerMediaObject!.fmtp = answerMediaObject.fmtp ?? [];

      var fmtp = (answerMediaObject.fmtp ?? []).firstWhereOrNull(
        (Fmtp f) => f.payload == codec.payloadType,
      );

      if (fmtp == null) {
        fmtp = Fmtp(payload: codec.payloadType, config: '');
        answerMediaObject.fmtp!.add(fmtp);
      }

      var parameters = parseParams(fmtp.config);

      switch (mimeType) {
        case 'audio/opus':
          {
            final spropStereo = codec.parameters['sprop-stereo'] as int?;

            if (spropStereo != null) {
              parameters['stereo'] = spropStereo > 0 ? 1 : 0;
            }
            break;
          }

        default:
          break;
      }

      // Write the codec fmtp.config back.
      fmtp.config = '';

      for (final key in parameters.keys.cast()) {
        if (fmtp.config.isNotEmpty) {
          fmtp.config += ';';
        }

        fmtp.config += '$key=${parameters[key]}';
      }
    }
  }
}
