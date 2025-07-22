import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mediasoup_client_flutter/src/handlers/sdp/media_section.dart';
import 'package:mediasoup_client_flutter/src/rtp_parameters.dart';

class PlanBUtils {
  static List<RtpEncodingParameters> getRtpEncodings(
    MediaObject? offerMediaObject,
    MediaStreamTrack track,
  ) {
    // First media SSRC (or the only one).
    int? firstSsrc;
    var ssrcs = <int>{};

    for (final line in offerMediaObject?.ssrcs ?? []) {
      if (line.attribute != 'msid') {
        continue;
      }

      var trackId = line.value.split(' ')[1];

      if (trackId == track.id) {
        var ssrc = line.id!;

        ssrcs.add(ssrc);

        firstSsrc ??= ssrc;
      }
    }

    if (ssrcs.isEmpty) {
      throw Exception(
        'a=ssrc line with msid information not found [track.id:${track.id}]',
      );
    }

    var ssrcToRtxSsrc = <dynamic, dynamic>{};

    // First assume RTX is used.
    for (final line in offerMediaObject?.ssrcGroups ?? []) {
      if (line.semantics != 'FID') {
        continue;
      }

      var tokens = line.ssrcs.split(' ');

      int? ssrc;
      if (tokens.length > 0) {
        ssrc = int.parse(tokens.first);
      }

      int? rtxSsrc;
      if (tokens.length > 1) {
        rtxSsrc = int.parse(tokens.last);
      }

      if (ssrcs.contains(ssrc)) {
        // Remove both the SSRC and RTX SSRC from the set so later we know that they
        // are already handled.
        ssrcs.remove(ssrc);
        ssrcs.remove(rtxSsrc);

        // Add to the map.
        ssrcToRtxSsrc[ssrc] = rtxSsrc;
      }
    }

    // If the set of SSRCs is not empty it means that RTX is not being used, so take
    // media SSRCs from there.
    for (final ssrc in ssrcs) {
      // Add to the map.
      ssrcToRtxSsrc[ssrc] = null;
    }

    var encodings = <RtpEncodingParameters>[];

    ssrcToRtxSsrc.forEach((ssrc, rtxSsrc) {
      var encoding = RtpEncodingParameters(ssrc: ssrc);

      if (rtxSsrc != null) {
        encoding.rtx = RtxSsrc(rtxSsrc);
      }

      encodings.add(encoding);
    });

    return encodings;
  }

  /// Adds multi-ssrc based simulcast into the given SDP media section offer.
  static void addLegacySimulcast(
    MediaObject? offerMediaObject,
    MediaStreamTrack track,
    int numStreams,
  ) {
    if (numStreams <= 1) {
      throw Exception('numStreams must be greater than 1');
    }

    int? firstSsrc;
    int? firstRtxSsrc;
    String? streamId;

    // Get the SSRC.
    var ssrcMsidLine = (offerMediaObject?.ssrcs ?? []).firstWhereOrNull((
      Ssrc line,
    ) {
      if (line.attribute != 'msid') {
        return false;
      }

      var trackId = line.value.split(' ')[1];

      if (trackId == track.id) {
        firstSsrc = line.id;
        streamId = line.value.split(' ')[0];

        return true;
      } else {
        return false;
      }
    });

    if (ssrcMsidLine == null) {
      throw Exception(
        'a=ssrc line with msid information not found [track.id:${track.id}]',
      );
    }

    // Get the SSRC for RTX.
    (offerMediaObject?.ssrcGroups ?? []).any((SsrcGroup line) {
      if (line.semantics != 'FID') {
        return false;
      }

      var ssrcs = line.ssrcs.split(' ');

      if (int.parse(ssrcs.first) == firstSsrc) {
        firstRtxSsrc = int.parse(ssrcs[1]);

        return true;
      } else {
        return false;
      }
    });

    var ssrcCnameLine = offerMediaObject?.ssrcs?.firstWhereOrNull(
      (Ssrc line) => line.attribute == 'cname' && line.id == firstSsrc,
    );

    if (ssrcCnameLine == null) {
      throw Exception(
        'a=ssrc line with cname information not found [track.id:${track.id}]',
      );
    }

    var cname = ssrcCnameLine.value;
    var ssrcs = <int>[];
    var rtxSsrcs = <int>[];

    for (var i = 0; i < numStreams; ++i) {
      ssrcs.add(firstSsrc! + i);

      if (firstRtxSsrc != null) {
        rtxSsrcs.add(firstRtxSsrc! + i);
      }
    }

    offerMediaObject?.ssrcGroups = offerMediaObject.ssrcGroups ?? [];
    offerMediaObject?.ssrcs = offerMediaObject.ssrcs ?? [];

    offerMediaObject?.ssrcGroups!.add(
      SsrcGroup(semantics: 'SIM', ssrcs: ssrcs.join(' ')),
    );

    for (var i = 0; i < ssrcs.length; ++i) {
      var ssrc = ssrcs[i];

      offerMediaObject?.ssrcs?.add(
        Ssrc(id: ssrc, attribute: 'cname', value: cname),
      );

      offerMediaObject?.ssrcs?.add(
        Ssrc(id: ssrc, attribute: 'msid', value: '$streamId ${track.id}'),
      );
    }

    for (var i = 0; i < rtxSsrcs.length; ++i) {
      var ssrc = ssrcs[i];
      var rtxSsrc = rtxSsrcs[i];

      offerMediaObject?.ssrcs?.add(
        Ssrc(id: rtxSsrc, attribute: 'cname', value: cname),
      );

      offerMediaObject?.ssrcs?.add(
        Ssrc(id: rtxSsrc, attribute: 'msid', value: '$streamId ${track.id}'),
      );

      offerMediaObject?.ssrcGroups?.add(
        SsrcGroup(semantics: 'FID', ssrcs: '$ssrc $rtxSsrc'),
      );
    }
  }
}
