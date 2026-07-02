# Conector de WhatsApp (MCP)

Servidor MCP (Model Context Protocol) para WhatsApp, vendorizado desde
[lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) (MIT license,
~5.9k estrellas en GitHub — el conector de WhatsApp mejor rankeado y más
confiable que encontré). Permite que Claude busque/lea mensajes, y envíe
mensajes y archivos multimedia a través de una cuenta de WhatsApp real.

Pensado como laboratorio para probar automatizaciones (ej. recordatorios de
deuda a proveedores) desde un número alternativo, no el principal.

## Cómo funciona

1. **`whatsapp-bridge/`** (Go): se conecta a la API multidispositivo de
   WhatsApp Web usando [whatsmeow](https://github.com/tulir/whatsmeow),
   autenticando por **código QR** con la app de WhatsApp del celular. Guarda
   el historial de mensajes en una base SQLite local (`whatsapp-bridge/store/`).
2. **`whatsapp-mcp-server/`** (Python): expone ese bridge como herramientas
   MCP para que un cliente como Claude Desktop / Claude Code las use.

Todo se queda en tu máquina: la base de datos y la sesión de WhatsApp viven
localmente, y solo se le manda al modelo lo que las herramientas consultan
explícitamente.

## Requisitos

- Go
- Python 3.6+
- [uv](https://docs.astral.sh/uv/) — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- FFmpeg (opcional, solo para convertir audio a nota de voz `.ogg`)
- Claude Desktop, Claude Code o Cursor como cliente MCP

## Instalación

1. **Levantar el bridge** (queda corriendo, maneja la conexión con WhatsApp):

   ```bash
   cd whatsapp-connector/whatsapp-bridge
   go run main.go
   ```

   La primera vez te va a mostrar un **código QR en la terminal**. Escanealo
   desde el WhatsApp del número alternativo: `Ajustes > Dispositivos
   vinculados > Vincular un dispositivo`. La sesión dura ~20 días antes de
   pedir un nuevo QR.

2. **Registrar el servidor MCP** en tu cliente (Claude Desktop, Claude Code o
   Cursor). Ejemplo de config:

   ```json
   {
     "mcpServers": {
       "whatsapp": {
         "command": "/ruta/a/uv",
         "args": [
           "--directory",
           "/ruta/absoluta/a/whatsapp-connector/whatsapp-mcp-server",
           "run",
           "main.py"
         ]
       }
     }
   }
   ```

   - `command`: salida de `which uv`.
   - El segundo valor de `args`: ruta absoluta a `whatsapp-mcp-server` en tu
     copia local de este repo.

   Para Claude Desktop, ese bloque va en
   `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
   o el equivalente en tu SO. Para Cursor, en `~/.cursor/mcp.json`.

3. Reiniciá el cliente. Debería aparecer "whatsapp" como integración
   disponible.

## Herramientas disponibles

- `search_contacts`, `list_chats`, `get_chat`, `get_direct_chat_by_contact`,
  `get_contact_chats`, `get_last_interaction`
- `list_messages`, `get_message_context`
- `send_message`, `send_file`, `send_audio_message`, `download_media`

## Seguridad y alcance

- **Cuenta no oficial**: usa la API de WhatsApp Web, no la API oficial de
  Business. Es el enfoque más popular y confiable en GitHub, pero como
  cualquier cliente no oficial puede violar los ToS de WhatsApp si se abusa
  (envíos masivos, spam). Uso previsto acá: mensajes puntuales 1 a 1 a
  proveedores, bajo volumen.
- **"Lethal trifecta"**: como cualquier MCP con acceso a datos privados +
  fuentes externas + capacidad de enviar, un prompt injection podría filtrar
  mensajes o enviar contenido no deseado. No conectar este servidor a fuentes
  no confiables sin revisar qué le estás dando de contexto.
- `whatsapp-bridge/store/` (contiene la sesión vinculada y el historial de
  mensajes en SQLite) y credenciales quedan **excluidos del repo** vía
  `.gitignore` — nunca deben subirse a git.

## Troubleshooting

- **No aparece el QR**: reiniciá `go run main.go`; verificá que la terminal
  soporte mostrar QR.
- **Límite de dispositivos vinculados**: en el celular, `Ajustes > Dispositivos
  vinculados`, quitá uno viejo.
- **Desincronización**: borrá `whatsapp-bridge/store/messages.db` y
  `whatsapp-bridge/store/whatsapp.db`, y volvé a vincular.

## Créditos

Código original: [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp)
(MIT, ver `LICENSE`). Este repo vendoriza una copia para uso propio.
