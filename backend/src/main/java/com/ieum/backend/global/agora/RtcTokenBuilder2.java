package com.ieum.backend.global.agora;

public class RtcTokenBuilder2 {

    public enum Role {
        ROLE_PUBLISHER(1),
        ROLE_SUBSCRIBER(2);

        private final int value;
        Role(int value) { this.value = value; }
        public int getValue() { return value; }
    }

    public String buildTokenWithUid(
            String appId,
            String appCertificate,
            String channelName,
            int uid,
            Role role,
            int tokenExpire,
            int privilegeExpire) throws Exception {

        return buildTokenWithUserAccount(appId, appCertificate, channelName,
                uid == 0 ? "" : String.valueOf(uid), role, tokenExpire, privilegeExpire);
    }

    public String buildTokenWithUserAccount(
            String appId,
            String appCertificate,
            String channelName,
            String account,
            Role role,
            int tokenExpire,
            int privilegeExpire) throws Exception {

        AccessToken2 token = new AccessToken2(appId, appCertificate, tokenExpire);
        AccessToken2.ServiceRtc serviceRtc = new AccessToken2.ServiceRtc(channelName, account);

        serviceRtc.addPrivilege(AccessToken2.ServiceRtc.PRIVILEGE_JOIN_CHANNEL, privilegeExpire);

        if (role == Role.ROLE_PUBLISHER) {
            serviceRtc.addPrivilege(AccessToken2.ServiceRtc.PRIVILEGE_PUBLISH_AUDIO_STREAM, privilegeExpire);
            serviceRtc.addPrivilege(AccessToken2.ServiceRtc.PRIVILEGE_PUBLISH_VIDEO_STREAM, privilegeExpire);
            serviceRtc.addPrivilege(AccessToken2.ServiceRtc.PRIVILEGE_PUBLISH_DATA_STREAM, privilegeExpire);
        }

        token.addService(serviceRtc);
        return token.build();
    }
}