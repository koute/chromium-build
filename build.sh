#!/usr/bin/false

CHROMIUM_URL="https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$VERSION.tar.xz"

rm -Rf chromium-build
mkdir chromium-build
pushd chromium-build

##
# Download and unpacking
##

curl -Lo chromium-$VERSION.tgz $CHROMIUM_URL
sha256sum -c ../CHECKSUMS
tar -xf chromium-$VERSION.tgz
mv "chromium-$VERSION" chromium

##
# Patches
##

pushd chromium

sed -i '/config("compiler")/ a cflags_cc = [ "-fno-delete-null-pointer-checks" ]' build/config/linux/BUILD.gn
find . -name '*.py' -exec sed -i -r 's|/usr/bin/python$|&2|g' {} +
python2 third_party/libaddressinput/chromium/tools/update-strings.py

popd # chromium

##
# Build
##

pushd chromium

mkdir tmp
export TMPDIR="`pwd`/tmp"

python2 build/linux/sysroot_scripts/install-sysroot.py --arch=amd64
python2 tools/gn/bootstrap/bootstrap.py
mkdir -p out/Release

echo 'import("//build/args/headless.gn")' > out/Release/args.gn

echo 'is_debug=false' >> out/Release/args.gn
echo 'clang_use_chrome_plugins=false' >> out/Release/args.gn
echo 'symbol_level=0' >> out/Release/args.gn

echo 'fatal_linker_warnings=false' >> out/Release/args.gn
echo 'treat_warnings_as_errors=false' >> out/Release/args.gn
echo 'remove_webcore_debug_symbols=true' >> out/Release/args.gn

echo 'use_cups=false' >> out/Release/args.gn
echo 'use_dbus=false' >> out/Release/args.gn
echo 'use_gconf=false' >> out/Release/args.gn
echo 'use_gio=false' >> out/Release/args.gn
echo 'use_gnome_keyring=false' >> out/Release/args.gn
echo 'use_gtk3=false' >> out/Release/args.gn
echo 'use_kerberos=false' >> out/Release/args.gn
echo 'use_libpci=false' >> out/Release/args.gn
echo 'use_pulseaudio=false' >> out/Release/args.gn
echo 'use_seccomp_bpf=false' >> out/Release/args.gn
echo 'use_udev=false' >> out/Release/args.gn

out/Release/gn gen out/Release --script-executable=/usr/bin/python2
ninja -C out/Release headless_shell

popd # chromium

##
# Package creation
##

mkdir destdir
install -d destdir/libs
install -m755 chromium/out/Release/headless_shell destdir
install -m655 chromium/out/Release/headless_lib.pak destdir
install -m755 chromium/out/Release/libosmesa.so destdir
strip destdir/headless_shell
cp $(ldd chromium/out/Release/headless_shell | awk '{print $3}' | sed '/^$/d') destdir/libs/

# ...

pushd destdir
rm -f ../../$OUTPUT
tar -zcf ../../$OUTPUT *
popd # destdir

##
# Cleanup
##

popd # chromium-build
