enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting;

  bool get isConnected => this == VpnConnectionStatus.connected;
  bool get isConnecting => this == VpnConnectionStatus.connecting;
  bool get isDisconnected => this == VpnConnectionStatus.disconnected;
  bool get isTransitioning => this == VpnConnectionStatus.connecting || this == VpnConnectionStatus.disconnecting;
}
