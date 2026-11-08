# Nyxz — imagem base (núcleo)
# Construída pelo GitHub Actions (.github/workflows/build.yml) e publicada em ghcr.io/<dono>/nyxz.
# Componentes opcionais NÃO entram aqui: vão para a imagem local personalizada (ver ARQUITETURA.md).

ARG FEDORA_VERSION=44

FROM scratch AS ctx
COPY build_files /

# Serviços da Nyxz em Rust: compilados aqui e só o binário vai para a imagem
# (o compilador não fica no sistema).
FROM quay.io/fedora/fedora:${FEDORA_VERSION} AS servicos
RUN --mount=type=cache,dst=/var/cache/libdnf5 dnf -y install cargo rust
COPY servicos /src
RUN --mount=type=cache,dst=/root/.cargo/registry \
    cd /src/nyxz-scoped && cargo build --release && \
    install -Dm0755 target/release/nyxz-scoped /out/usr/libexec/nyxz/nyxz-scoped

FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION}

ARG FEDORA_VERSION
ARG NYXZ_VERSION=dev
# Endereço desta imagem no registro: base da imagem local personalizada do usuário.
ARG NYXZ_IMAGE_BASE=ghcr.io/xaucutin/nyxz:44

# Arquivos que vão direto para o sistema (configurações, scripts, padrões do Hyprland).
COPY system_files/ /
COPY --from=servicos /out/ /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    FEDORA_VERSION="${FEDORA_VERSION}" NYXZ_VERSION="${NYXZ_VERSION}" NYXZ_IMAGE_BASE="${NYXZ_IMAGE_BASE}" bash /ctx/build.sh

RUN bootc container lint
