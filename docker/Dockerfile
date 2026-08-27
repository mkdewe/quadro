# syntax=docker/dockerfile:1.7
#
# quadro — container recipe
#
# CYANA and Xplor-NIH are NOT part of this repository and NOT part of the default
# build context. They arrive through BuildKit *named build contexts*, so the same
# Dockerfile works whether they sit in this repo's third_party/ or somewhere else
# entirely (e.g. shared between several quadro versions in a parent repository).
#
#   tools/build.sh                     ← recommended; wraps the call below
#
#   DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t quadro14l:latest . \
#       --build-context cyana=third_party/cyana-2.1 \
#       --build-context xplor=third_party/xplor-nih-2.39
#
# ⚠ The resulting image contains CYANA and Xplor-NIH. Do not push it to any
#   registry a non-licensee can pull from.

FROM ubuntu:22.04

# Which engine this image runs. Bumping quadro to a new version means replacing
# engine/ and overriding these two — nothing else in the recipe changes.
ARG QUADRO_EXE=quadro14L.exe
ARG QUADRO_ALT=alternatywa14L.exe

ENV DEBIAN_FRONTEND=noninteractive

# ── 1. System packages ───────────────────────────────────────────────────────
# CYANA 2.1 ships 32-bit binaries, hence the i386 architecture and the :i386
# runtime libraries. libtinfo5/libncurses5 are likewise needed by the old
# CYANA build and are no longer pulled in by default on 22.04.
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        bash wget curl file gawk sed grep coreutils unzip locales \
        build-essential gfortran libgfortran5 libstdc++6 zlib1g \
        libncurses6 libc6-dev libgomp1 \
        libc6:i386 libstdc++6:i386 libncurses5:i386 zlib1g:i386 libgcc-s1:i386 \
        libncurses5 libtinfo5 \
        dos2unix \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ── 2. Externally licensed dependencies (named build contexts) ───────────────
COPY --from=cyana . /opt/bin/cyana-2.1/
COPY --from=xplor . /opt/bin/xplor-nih-2.39/

# ── 3. quadro itself ─────────────────────────────────────────────────────────
# engine/ is copied flat into /opt/bin because the engine resolves its data
# files relative to the working directory (DIR="./" — see step 5). Keeping the
# layout flat is what makes that assumption hold.
COPY engine/ /opt/bin/
COPY docker/entrypoint.sh /usr/local/bin/quadro-run

# ── 4. Normalise line endings ────────────────────────────────────────────────
# The engine and its .cya/.lib data files are authored on Windows and carry
# CRLF. awk and CYANA both choke on the stray \r. Converting at build time keeps
# the committed files byte-identical to what the author delivered.
RUN find /opt/bin -type f -exec sh -c \
        'file "$1" | grep -qE "text|script" && dos2unix "$1"' _ {} \; 2>/dev/null || true && \
    dos2unix /usr/local/bin/quadro-run && chmod +x /usr/local/bin/quadro-run

# ── 5. Pin the engine's data directory to the working directory ──────────────
# Some releases carry an absolute DIR="..." path. The engine is always invoked
# from /opt/bin, where its data files live, so DIR must be "./". Rewriting here
# rather than in the repo keeps engine/ byte-identical to the delivered source.
# Releases that already say DIR="./" are left untouched by the regex — the
# check below covers both.
RUN sed -i 's|^DIR="/.*"$|DIR="./"|' "/opt/bin/${QUADRO_EXE}" && \
    grep -q '^DIR="\./"$' "/opt/bin/${QUADRO_EXE}" || \
    { echo "FATAL: could not pin DIR=\"./\" in ${QUADRO_EXE}"; exit 1; }

# ── 6. Xplor-NIH layout ──────────────────────────────────────────────────────
# Xplor resolves its own binaries through arch/equivList; the distribution
# leaves that to its installer, which we bypass.
RUN cd /opt/bin/xplor-nih-2.39 && \
    mkdir -p arch/Linux_x86_64 && \
    echo "Linux_x86_64" > arch/Linux_x86_64/equivList && \
    echo "Linux_x86_64" > arch/equivList && \
    if [ -d bin.Linux_x86_64 ]; then \
        mkdir -p bin && cp -r bin.Linux_x86_64/* bin/ && chmod +x bin/* 2>/dev/null || true; \
    fi && \
    chmod +x bin/xplor 2>/dev/null || true

# ── 7. CYANA layout ──────────────────────────────────────────────────────────
RUN cd /opt/bin/cyana-2.1 && \
    chmod +x cyana cyana.sh 2>/dev/null || true && \
    if [ -f cyana.sh ]; then ln -sf /opt/bin/cyana-2.1/cyana.sh /usr/local/bin/cyana; fi

# ── 8. Permissions ───────────────────────────────────────────────────────────
RUN chmod -R a+rX /opt/bin && \
    chmod +x "/opt/bin/${QUADRO_EXE}" "/opt/bin/${QUADRO_ALT}" \
             /opt/bin/cyana2xplor.exe /opt/bin/xplor2pdb2.exe \
             /opt/bin/t2dih.exe /opt/bin/tor3aa 2>/dev/null || true && \
    chmod +x /opt/bin/cyana2xplor14L.exe 2>/dev/null || true

# ── 9. Environment ───────────────────────────────────────────────────────────
ENV QUADRO_EXE=${QUADRO_EXE} \
    QUADRO_ALT=${QUADRO_ALT} \
    QUADRO_HOME=/opt/bin \
    PATH="/opt/bin:/opt/bin/cyana-2.1:/opt/bin/xplor-nih-2.39/bin:${PATH}" \
    CYANA="/opt/bin/cyana-2.1" \
    XPLOR="/opt/bin/xplor-nih-2.39" \
    TOPPAR="/opt/bin/xplor-nih-2.39/toppar" \
    LD_LIBRARY_PATH="/opt/bin/xplor-nih-2.39/bin:/opt/bin/xplor-nih-2.39/bin.Linux_x86_64:/usr/lib/x86_64-linux-gnu:/usr/lib32"

RUN ln -sf /opt/bin/xplor-nih-2.39 /opt/xplor-nih-2.39

# ── 10. Build-time smoke check ───────────────────────────────────────────────
# Fails the build if a dependency was supplied but is not actually runnable —
# far cheaper to find here than three minutes into a structure calculation.
RUN set -e; \
    awk --version 2>&1 | grep -q "GNU Awk" \
        || { echo "FATAL: 'awk' is not GNU awk. The engine uses gawk-only features (true"; \
             echo "       multidimensional arrays, strtonum) and silently misbehaves under mawk."; exit 1; }; \
    test -x /opt/bin/cyana-2.1/cyana        || { echo "FATAL: CYANA binary missing or not executable"; exit 1; }; \
    test -x /opt/bin/xplor-nih-2.39/bin/xplor || { echo "FATAL: Xplor-NIH binary missing or not executable"; exit 1; }; \
    test -x "/opt/bin/${QUADRO_EXE}"        || { echo "FATAL: ${QUADRO_EXE} missing or not executable"; exit 1; }; \
    for f in tetrad.lib bp.lib other_residues.lib ATOMTYPES.txt ryb.cya sugarbond.cya mp_makeaco.cya tor3aa; do \
        test -f "/opt/bin/$f" || { echo "FATAL: engine data file $f missing"; exit 1; }; \
    done; \
    echo "quadro image OK: engine=${QUADRO_EXE} alt=${QUADRO_ALT}"

# ── 11. Runtime ──────────────────────────────────────────────────────────────
# /work is the mount point for the user's inputs and outputs.
WORKDIR /work
VOLUME ["/work"]
ENTRYPOINT ["/usr/local/bin/quadro-run"]
CMD ["--help"]
