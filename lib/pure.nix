{ lib }:
{
  systemToPlatform =
    system:
    {
      "x86_64-linux" = "linux/amd64";
      "aarch64-linux" = "linux/arm64";
    }
    .${system};
}
