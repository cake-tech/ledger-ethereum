class EthereumAppConfig {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;
  final int flags;

  EthereumAppConfig(
      this.majorVersion, this.minorVersion, this.patchVersion, this.flags);

  String get version => "$majorVersion.$minorVersion.$patchVersion";
}
