{ stdenv, squashfsTools, closureInfo, findutils

, # The root directory of the squashfs filesystem is filled with the
  # closures of the Nix store paths listed here.
  storeContents ? []
, # Compression parameters.
  # For zstd compression you can use "zstd -Xcompression-level 6".
  comp ? "xz -Xdict-size 100%"
}:

stdenv.mkDerivation {
  name = "squashfs.img";

  nativeBuildInputs = [ squashfsTools findutils ];

  buildCommand =
    ''
      closureInfo=${closureInfo { rootPaths = storeContents; }}

      # Also include a manifest of the closures in a format suitable
      # for nix-store --load-db.
      cp $closureInfo/registration nix-path-registration

      cat << EOF > mksquashfs.sh
      exec mksquashfs "\$@" $out -no-recovery -keep-as-directory -all-root -b 1048576 -comp ${comp}
      EOF

      # Generate the squashfs image.
      echo "nix-path-registration" | cat - $closureInfo/store-paths | xargs bash mksquashfs.sh
    '';
}
