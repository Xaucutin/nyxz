# Nyxz — imagem base (núcleo)
# Construída pelo GitHub Actions (.github/workflows/build.yml) e publicada em ghcr.io/<dono>/nyxz.
# Componentes opcionais NÃO entram aqui: vão para a imagem local personalizada (ver ARQUITETURA.md).

ARG FEDORA_VERSION=44

FROM scratch AS ctx
COPY build_files /

FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION}

ARG FEDORA_VERSION
ARG NYXZ_VERSION=dev

# Arquivos que vão direto para o sistema (configurações, scripts, padrões do Hyprland).
COPY system_files/ /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    FEDORA_VERSION="${FEDORA_VERSION}" NYXZ_VERSION="${NYXZ_VERSION}" bash /ctx/build.sh

RUN bootc container lint
