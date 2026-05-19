package com.ieum.backend.global.agora;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;
import java.util.zip.Deflater;

public class AccessToken2 {
    public static final int VERSION = 7;
    public static final String VERSION_STR = "007";

    public String appId;
    public String appCertificate;
    public int expire;
    public Map<Short, Service> services = new HashMap<>();

    public AccessToken2(String appId, String appCertificate, int expire) {
        this.appId = appId;
        this.appCertificate = appCertificate;
        this.expire = expire;
    }

    public void addService(Service service) {
        services.put(service.getServiceType(), service);
    }

    public String build() throws Exception {
        int issueTs = (int) (System.currentTimeMillis() / 1000);
        byte[] signing = generateSigning(issueTs);
        byte[] content = packContent(issueTs, signing);
        byte[] signature = encodeHMACSHA256(signing, content);
        byte[] result = packResult(signature, content);
        return VERSION_STR + appId + Base64.getEncoder().encodeToString(compress(result));
    }

    private byte[] generateSigning(int issueTs) throws Exception {
        byte[] salt = intToBytes(issueTs);
        byte[] expireBytes = intToBytes(expire);
        byte[] combined = new byte[salt.length + expireBytes.length];
        System.arraycopy(salt, 0, combined, 0, salt.length);
        System.arraycopy(expireBytes, 0, combined, salt.length, expireBytes.length);
        return encodeHMACSHA256(appCertificate.getBytes(), combined);
    }

    private byte[] packContent(int issueTs, byte[] signing) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(intToBytes(issueTs));
        out.write(intToBytes(expire));
        out.write(signing);
        out.write(shortToBytes((short) services.size()));
        TreeMap<Short, Service> sorted = new TreeMap<>(services);
        for (Service service : sorted.values()) {
            out.write(service.pack());
        }
        return out.toByteArray();
    }

    private byte[] packResult(byte[] signature, byte[] content) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write(shortToBytes((short) signature.length));
        out.write(signature);
        out.write(content);
        return out.toByteArray();
    }

    private byte[] compress(byte[] data) {
        Deflater deflater = new Deflater();
        deflater.setInput(data);
        deflater.finish();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        while (!deflater.finished()) {
            int count = deflater.deflate(buffer);
            out.write(buffer, 0, count);
        }
        return out.toByteArray();
    }

    public static byte[] encodeHMACSHA256(byte[] key, byte[] data)
            throws NoSuchAlgorithmException, InvalidKeyException {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key, "HmacSHA256"));
        return mac.doFinal(data);
    }

    public static byte[] intToBytes(int value) {
        return ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(value).array();
    }

    public static byte[] shortToBytes(short value) {
        return ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN).putShort(value).array();
    }

    public abstract static class Service {
        private short serviceType;
        protected Map<Short, Integer> privileges = new TreeMap<>();

        public Service(short serviceType) {
            this.serviceType = serviceType;
        }

        public short getServiceType() {
            return serviceType;
        }

        public void addPrivilege(short privilege, int expire) {
            privileges.put(privilege, expire);
        }

        public byte[] pack() throws Exception {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            out.write(shortToBytes(serviceType));
            out.write(packPrivileges());
            return out.toByteArray();
        }

        private byte[] packPrivileges() throws Exception {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            out.write(shortToBytes((short) privileges.size()));
            for (Map.Entry<Short, Integer> entry : privileges.entrySet()) {
                out.write(shortToBytes(entry.getKey()));
                out.write(intToBytes(entry.getValue()));
            }
            return out.toByteArray();
        }
    }

    public static class ServiceRtc extends Service {
        public static final short SERVICE_TYPE = 1;
        public static final short PRIVILEGE_JOIN_CHANNEL = 1;
        public static final short PRIVILEGE_PUBLISH_AUDIO_STREAM = 2;
        public static final short PRIVILEGE_PUBLISH_VIDEO_STREAM = 3;
        public static final short PRIVILEGE_PUBLISH_DATA_STREAM = 4;

        private String channelName;
        private String uid;

        public ServiceRtc(String channelName, String uid) {
            super(SERVICE_TYPE);
            this.channelName = channelName;
            this.uid = uid;
        }

        @Override
        public byte[] pack() throws Exception {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            out.write(shortToBytes(SERVICE_TYPE));
            byte[] channelBytes = channelName.getBytes();
            out.write(shortToBytes((short) channelBytes.length));
            out.write(channelBytes);
            byte[] uidBytes = uid.getBytes();
            out.write(shortToBytes((short) uidBytes.length));
            out.write(uidBytes);
            out.write(packPrivilegesPublic());
            return out.toByteArray();
        }

        private byte[] packPrivilegesPublic() throws Exception {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            out.write(shortToBytes((short) privileges.size()));
            for (Map.Entry<Short, Integer> entry : privileges.entrySet()) {
                out.write(shortToBytes(entry.getKey()));
                out.write(intToBytes(entry.getValue()));
            }
            return out.toByteArray();
        }
    }
}