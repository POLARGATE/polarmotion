# PolarMotion

De [Polargate](https://polargate.ai). Una biblioteca de 66 estilos de vídeo hechos enteramente con código, para que Claude Code dirija, anime, ponga voz y música y monte el vídeo en tu ordenador: pizarra, acuarela, dibujos animados, documental, datos, 3D y muchos más.

Se usa desde la skill **Haz reels** de Polargate:

```
/plugin marketplace add POLARGATE/skills
/plugin install polargate-haz-reels@polargate
```

Después pide a Claude, con tus palabras: «Hazme un vídeo de 30 segundos en estilo pizarra que explique cómo funciona mi tienda».

- Los estilos, en español: [`styles/INDICE.md`](styles/INDICE.md).
- Todo funciona en tu ordenador: el render, la voz (Kokoro, también en español) y la música. No hace falta ninguna clave ni servicio de pago.
- Hace falta Node 20 o superior, ffmpeg 7 o superior y Python 3.11 a 3.13. Lo demás lo instala `sh tools/setup.sh deps` cuando tú lo dices.
- Los recursos grandes (voz, instrumentos, texturas) se descargan de este repositorio, con su comprobación sha256: `sh tools/fetch.sh`.

## Créditos

Basado en [Lemo-Opuscar](https://github.com/lemomo-ai/lemo-opuscar), de LemoLab, con licencia MIT (código) y CC BY 4.0 (estilos y demos), a partir del commit `bebbbe1aa92a`. Detalle de licencias y cambios en [`NOTICE`](NOTICE) y [`LICENSE`](LICENSE).
