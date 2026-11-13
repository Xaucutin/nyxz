#!/usr/bin/bash
# Monta o núcleo da Nyxz dentro da imagem fedora-bootc.
# Pacotes "obrigatórios" fazem o build falhar se faltarem; "se disponível" só avisam.
set -euo pipefail

CTX="$(dirname "$(readlink -f "$0")")"
FEDORA_VERSION="${FEDORA_VERSION:-$(rpm -E %fedora)}"
NYXZ_VERSION="${NYXZ_VERSION:-dev}"

log() { printf '\n==> %s\n' "$*"; }

lista() { grep -Ev '^\s*(#|$)' "$CTX/packages/$1" | tr '\n' ' '; }

# ---------------------------------------------------------------- repositórios
log "Repositórios: RPM Fusion e COPRs"
dnf -y install \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

copr() {
  # $1 = dono/projeto. Baixa o .repo do COPR para a versão do Fedora usada.
  local dono="${1%/*}" projeto="${1#*/}"
  local destino="/etc/yum.repos.d/_copr_${dono}-${projeto}.repo"
  if curl -fsSL "https://copr.fedorainfracloud.org/coprs/${dono}/${projeto}/repo/fedora-${FEDORA_VERSION}/${dono}-${projeto}-fedora-${FEDORA_VERSION}.repo" -o "$destino"; then
    echo "COPR ${1}: ok"
  else
    echo "AVISO: COPR ${1} não tem build para o Fedora ${FEDORA_VERSION}"
    rm -f "$destino"
  fi
}
while read -r repo; do copr "$repo"; done < <(grep -Ev '^\s*(#|$)' "$CTX/packages/copr.txt")

# ---------------------------------------------------------------- codecs
# Vem ANTES dos outros pacotes e SEM --allowerasing: no primeiro teste, trocar os
# codecs depois, com --allowerasing, desinstalou o Hyprland sem dar erro.
# O Mesa do Fedora vem sem H.264/HEVC por causa de patentes; sem isto, Nyxz Share,
# replay e gravação ficariam só com AV1.
log "Codecs completos (H.264/HEVC na placa de vídeo, ffmpeg completo)"
if rpm -q mesa-va-drivers >/dev/null 2>&1; then
  dnf -y swap mesa-va-drivers mesa-va-drivers-freeworld || echo "AVISO: troca do mesa-va-drivers falhou"
else
  dnf -y install --setopt=install_weak_deps=False mesa-va-drivers-freeworld || echo "AVISO: mesa-va-drivers-freeworld não foi instalado"
fi
if rpm -q ffmpeg-free >/dev/null 2>&1; then
  dnf -y swap ffmpeg-free ffmpeg || echo "AVISO: troca do ffmpeg falhou"
else
  dnf -y install --setopt=install_weak_deps=False ffmpeg-libs || echo "AVISO: ffmpeg-libs não foi instalado"
fi

# ---------------------------------------------------------------- pacotes
log "Pacotes obrigatórios"
# shellcheck disable=SC2046
dnf -y install --setopt=install_weak_deps=False $(lista obrigatorios.txt)
log "KDE Plasma"
dnf -y install --setopt=install_weak_deps=False $(lista plasma.txt)

log "Pacotes se disponível"
# shellcheck disable=SC2046
dnf -y install --setopt=install_weak_deps=False --skip-unavailable $(lista se-disponivel.txt)

# ---------------------------------------------------------------- sessão por escopos
# uwsm e app2unit não têm pacote para o Fedora 44 nos repositórios usados.
# Instalados do código-fonte, em versões fixas (ARQUITETURA.md, 2.1).
log "app2unit e uwsm (código-fonte)"
APP2UNIT_VERSION="v1.4.4"
UWSM_VERSION="v0.27.1"

if ! command -v app2unit >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/Vladimir-csp/app2unit/${APP2UNIT_VERSION}/app2unit" -o /usr/bin/app2unit \
    && chmod 0755 /usr/bin/app2unit \
    || echo "AVISO: app2unit não foi instalado"
fi

if ! command -v uwsm >/dev/null 2>&1; then
  dnf -y install --setopt=install_weak_deps=False python3-dbus python3-pyxdg newt
  build_deps="meson ninja-build scdoc git-core"
  # shellcheck disable=SC2086
  build_deps_novos=$(for p in $build_deps; do rpm -q "$p" >/dev/null 2>&1 || echo "$p"; done)
  # Só remove depois o que entrou agora: tirar o git-core levava junto o Plasma
  dnf -y install --setopt=install_weak_deps=False $build_deps
  tmp="$(mktemp -d)"
  if git clone --depth 1 --branch "${UWSM_VERSION}" https://github.com/Vladimir-csp/uwsm.git "$tmp/uwsm" \
     && meson setup "$tmp/uwsm/build" "$tmp/uwsm" --prefix=/usr -Duuctl=disabled -Dfumon=disabled -Duwsm-app=enabled \
     && meson install -C "$tmp/uwsm/build"; then
    echo "uwsm ${UWSM_VERSION}: ok"
  else
    echo "AVISO: uwsm não foi instalado (a sessão usa Hyprland direto)"
  fi
  rm -rf "$tmp"
  # shellcheck disable=SC2086
  dnf -y remove $build_deps_novos || true
fi

# ---------------------------------------------------------------- vídeo como papel de parede
# O mpvpaper não tem pacote para o Fedora 44 nos repositórios usados: código-fonte,
# versão fixa. Só o binário e a mpv-libs ficam no sistema.
log "mpvpaper (código-fonte)"
MPVPAPER_VERSION="1.9"
if ! command -v mpvpaper >/dev/null 2>&1; then
  dnf -y install --setopt=install_weak_deps=False mpv-libs
  build_deps="meson ninja-build gcc git-core pkgconf-pkg-config mpv-devel wayland-devel wayland-protocols-devel mesa-libEGL-devel"
  # shellcheck disable=SC2086
  build_deps_novos=$(for p in $build_deps; do rpm -q "$p" >/dev/null 2>&1 || echo "$p"; done)
  # Só remove depois o que entrou agora: tirar o git-core levava junto o Plasma
  dnf -y install --setopt=install_weak_deps=False $build_deps
  tmp="$(mktemp -d)"
  if git clone --depth 1 --branch "${MPVPAPER_VERSION}" https://github.com/GhostNaN/mpvpaper.git "$tmp/mpvpaper" \
     && meson setup "$tmp/mpvpaper/build" "$tmp/mpvpaper" --prefix=/usr --buildtype=release \
     && ninja -C "$tmp/mpvpaper/build" \
     && install -Dm0755 "$tmp/mpvpaper/build/mpvpaper" /usr/bin/mpvpaper \
     && { [ ! -f "$tmp/mpvpaper/build/mpvpaper-holder" ] || install -Dm0755 "$tmp/mpvpaper/build/mpvpaper-holder" /usr/bin/mpvpaper-holder; }; then
    echo "mpvpaper ${MPVPAPER_VERSION}: ok"
  else
    echo "AVISO: mpvpaper não foi instalado (papel de parede em vídeo indisponível)"
  fi
  rm -rf "$tmp"
  # shellcheck disable=SC2086
  dnf -y remove $build_deps_novos || true
fi

# ---------------------------------------------------------------- fontes
log "Fontes Geist e Geist Mono"
GEIST_VERSION="v1.9.2"
tmp="$(mktemp -d)"
curl -fsSL "https://github.com/vercel/geist-font/releases/download/${GEIST_VERSION}/geist-font-${GEIST_VERSION}.zip" -o "$tmp/geist.zip"
mkdir -p /usr/share/fonts/geist
python3 - "$tmp/geist.zip" /usr/share/fonts/geist <<'PY'
import sys, zipfile, os
zip_path, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as z:
    for n in z.namelist():
        # Só as fontes estáticas em OTF (variáveis e webfonts ficam de fora).
        if n.lower().endswith(".otf") and "variable" not in n.lower():
            with z.open(n) as src, open(os.path.join(dest, os.path.basename(n)), "wb") as dst:
                dst.write(src.read())
PY
rm -rf "$tmp"
fc-cache -f /usr/share/fonts/geist

# ---------------------------------------------------------------- Flathub
log "Flathub como remoto padrão"
mkdir -p /etc/flatpak/remotes.d
curl -fsSL https://dl.flathub.org/repo/flathub.flatpakrepo -o /etc/flatpak/remotes.d/flathub.flatpakrepo

# ---------------------------------------------------------------- identidade
log "Identidade do sistema"
sed -i \
  -e 's/^NAME=.*/NAME="Nyxz"/' \
  -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Nyxz ${NYXZ_VERSION} (Fedora ${FEDORA_VERSION})\"/" \
  /usr/lib/os-release
grep -q '^VARIANT_ID=' /usr/lib/os-release \
  && sed -i 's/^VARIANT_ID=.*/VARIANT_ID=nyxz/' /usr/lib/os-release \
  || echo 'VARIANT_ID=nyxz' >> /usr/lib/os-release
# Fuso padrão: Brasília. Sem isto, o relógio ficava em UTC (3 h adiantado) mesmo com
# "timezone America/Sao_Paulo" no instalador. Dá para mudar em Configurações.
ln -sf ../usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
mkdir -p /usr/share/nyxz
echo "${NYXZ_VERSION}" > /usr/share/nyxz/versao
echo "${NYXZ_IMAGE_BASE:-ghcr.io/xaucutin/nyxz:${FEDORA_VERSION}}" > /usr/share/nyxz/imagem-base
python3 -I -c 'import json; json.load(open("/usr/share/nyxz/catalogo.json"))' || { echo "ERRO: catalogo.json inválido"; exit 1; }

# A tela de login usa o mesmo tema e os mesmos ícones do shell principal.
ln -sf ../nyxz/Tema.qml /etc/xdg/quickshell/nyxz-login/Tema.qml
ln -sfn ../nyxz/icones /etc/xdg/quickshell/nyxz-login/icones
# As Configurações também usam o tema, o controle deslizante e os ícones.
ln -sf ../nyxz/Tema.qml /etc/xdg/quickshell/nyxz-config/Tema.qml
ln -sf ../nyxz/Deslizante.qml /etc/xdg/quickshell/nyxz-config/Deslizante.qml
ln -sfn ../nyxz/icones /etc/xdg/quickshell/nyxz-config/icones
# O Nyxz Setup reaproveita o tema, os ícones e os componentes das Configurações.
ln -sf ../nyxz/Tema.qml /etc/xdg/quickshell/nyxz-setup/Tema.qml
ln -sfn ../nyxz/icones /etc/xdg/quickshell/nyxz-setup/icones
for f in Botao.qml ListaComponentes.qml Executor.qml; do
  ln -sf "../nyxz-config/$f" "/etc/xdg/quickshell/nyxz-setup/$f"
done
# O Dev Hub usa o tema, os ícones e os componentes das Configurações.
ln -sf ../nyxz/Tema.qml /etc/xdg/quickshell/nyxz-dev/Tema.qml
ln -sfn ../nyxz/icones /etc/xdg/quickshell/nyxz-dev/icones
for f in Botao.qml Pagina.qml Linha.qml Comando.qml Interruptor.qml Campo.qml; do
  ln -sf "../nyxz-config/$f" "/etc/xdg/quickshell/nyxz-dev/$f"
done
# A biblioteca de jogos usa o tema, os ícones e os componentes das Configurações.
ln -sf ../nyxz/Tema.qml /etc/xdg/quickshell/nyxz-jogos/Tema.qml
ln -sfn ../nyxz/icones /etc/xdg/quickshell/nyxz-jogos/icones
for f in Botao.qml Comando.qml Campo.qml; do
  ln -sf "../nyxz-config/$f" "/etc/xdg/quickshell/nyxz-jogos/$f"
done

# ---------------------------------------------------------------- serviços
log "Serviços"
chmod 0755 /usr/bin/nyx /usr/libexec/nyxz/* /usr/libexec/nyxz/extras/*
systemctl set-default graphical.target
systemctl enable greetd.service
# Atualizações: o timer padrão do bootc instala e REINICIA o PC sozinho. A Nyxz só
# baixa em segundo plano e aplica no próximo boot que o usuário fizer.
systemctl disable bootc-fetch-apply-updates.timer 2>/dev/null || true
systemctl mask bootc-fetch-apply-updates.timer 2>/dev/null || true
systemctl enable nyxz-atualizar.timer nyxz-migracoes.service nyxz-rede.service nyxz-discos.timer nyxz-dualboot.service
# Saúde dos discos: o timer da Nyxz confere a cada 30 min; o smartd ficaria rodando sempre
systemctl disable smartd.service 2>/dev/null || true
# Bluetooth: só acorda quando há adaptador (bluetooth.target)
systemctl enable bluetooth.service 2>/dev/null || true
# Servidor SSH desligado por padrão: num computador pessoal, a porta 22 aberta na rede
# é risco à toa. Liga pelo Dev Hub → SSH quando precisar.
systemctl disable sshd.service sshd.socket 2>/dev/null || true
# Serviços de usuário da Nyxz: ligados para todos os usuários, sobem com a sessão gráfica.
systemctl --global enable nyxz-scoped.service nyxz-discos-alerta.path nyxz-stats.service nyxz-chaveiro.service nyxz-ajustes-apps.service nyxz-clipboard.service
# Repositórios de terceiros ficam desligados no sistema instalado: as atualizações
# vêm pela imagem nova, não por dnf.
sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/_copr_*.repo 2>/dev/null || true

# ---------------------------------------------------------------- visual (teste no PC real)
log "Tema escuro dos apps Qt, ícones e tela de boot"
# Cores do Breeze escuro no kdeglobals do sistema (o Dolphin lê daqui)
[ -f /usr/share/color-schemes/BreezeDark.colors ] && sed '/^\[General\]/,/^$/d' /usr/share/color-schemes/BreezeDark.colors >> /etc/xdg/kdeglobals
# Tela de boot: logo NX + animação do tema "spinner" (frames throbber/animation)
T=/usr/share/plymouth/themes/nyxz
if command -v plymouth-set-default-theme >/dev/null && [ -d /usr/share/plymouth/themes/spinner ]; then
  cp /usr/share/plymouth/themes/spinner/{throbber,animation}-*.png "$T"/ 2>/dev/null || true
  rsvg-convert -w 160 "$T/nyxz-mark.svg" -o "$T/watermark.png" || echo "AVISO: logo do boot não gerado"
  plymouth-set-default-theme nyxz
  KVER="$(ls /usr/lib/modules | sort -V | tail -1)"
  dracut --no-hostonly --kver "$KVER" --reproducible --add plymouth -f "/usr/lib/modules/$KVER/initramfs.img"     || echo "AVISO: initramfs com a tela de boot falhou"
else
  echo "AVISO: Plymouth indisponível; boot continua com texto"
fi

# ---------------------------------------------------------------- conferência
# Falha o build se algum pacote obrigatório sumiu no caminho (ex.: removido por
# conflito) ou se a sessão não tiver o que precisa para abrir.
log "Conferindo o núcleo"
# shellcheck disable=SC2046
faltando="$(rpm -q $(lista obrigatorios.txt) | grep 'is not installed' || true)"
if [ -n "$faltando" ]; then
  echo "ERRO: pacotes obrigatórios ausentes:"
  echo "$faltando"
  exit 1
fi
grep -h '^Exec=' /usr/share/wayland-sessions/plasma*.desktop || { echo "ERRO: sessão do Plasma não instalada"; ls /usr/share/wayland-sessions; exit 1; }
for bin in Hyprland greetd foot /usr/libexec/nyxz/nyxz-scoped; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERRO: $bin não está no sistema"; exit 1; }
done
ls /usr/share/wayland-sessions/*.desktop >/dev/null 2>&1 || { echo "ERRO: nenhuma sessão Wayland instalada"; exit 1; }
for bin in uwsm app2unit quickshell cage tuigreet; do
  command -v "$bin" >/dev/null 2>&1 || echo "AVISO: $bin não está no sistema"
done
echo "Sessões disponíveis: $(ls /usr/share/wayland-sessions/)"

# ---------------------------------------------------------------- limpeza
log "Limpeza"
dnf clean all
rm -rf /var/log/dnf5.log* /tmp/* || true
