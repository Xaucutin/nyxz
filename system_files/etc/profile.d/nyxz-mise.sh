# Nyxz: linguagens instaladas pelo mise (Apps e componentes → Desenvolvimento).
# Só entra no PATH se o usuário tiver instalado alguma.
if [ -d "$HOME/.local/share/mise/shims" ]; then
  case ":$PATH:" in
    *":$HOME/.local/share/mise/shims:"*) ;;
    *) PATH="$HOME/.local/share/mise/shims:$PATH" ;;
  esac
fi
