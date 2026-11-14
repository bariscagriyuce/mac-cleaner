# YUCE Cleaner

[English](README.md) · [Türkçe](README.tr.md) · **Português (Brasil)**

O **YUCE Cleaner para Mac** é um app nativo para macOS que mostra o que existe dentro dos misteriosos **“Dados do Sistema”** nos ajustes de armazenamento e ajuda você a recuperar espaço em disco com segurança.

## Recursos

- **Visão geral do disco:** espaço usado e livre, e quanto cada categoria ocupa.
- **Limpeza Rápida:** um botão que remove apenas dados seguros e recriáveis: caches de apps, logs, caches de ferramentas de desenvolvimento, DerivedData / DeviceSupport do Xcode, simuladores indisponíveis e a Lixeira. Nunca mexe em dados pessoais, configurações de apps nem nos Archives do Xcode, e ignora os caches de apps que estão abertos.
- **13 categorias**, cada uma marcada como *Pode apagar com segurança*, *Revise antes de apagar* ou *Apenas informativo*:
  Caches de apps · Logs e relatórios de falhas · Dados do Xcode · Simuladores iOS · Caches de ferramentas de desenvolvimento (npm, pip, uv, Gradle, Cargo, Maven, Go…) · Máquinas virtuais, Android e Docker · Backups de iPhone/iPad · Dados de suporte de apps · Anexos do Mail e Mensagens · Downloads · Lixeira · Snapshots locais do Time Machine · Arquivos temporários do sistema
- Botões **Selecionar Tudo / Apagar Selecionados** em todas as categorias, além de clique direito → *Mostrar no Finder*.
- **Explorador de Pastas:** navegue por qualquer pasta ordenada por tamanho e entre nela com um clique duplo para descobrir o que está ocupando o disco.
- **Seguro por padrão:** os itens vão para a Lixeira (podem ser restaurados), a menos que você escolha *Apagar Permanentemente*. Pastas críticas como sua pasta pessoal, Documentos, Mesa, `~/Library` e `/System` são protegidas e não podem ser apagadas.
- **Idiomas:** inglês, turco e português do Brasil. O app segue o idioma do macOS e usa inglês como padrão.
- **Atualizações automáticas:** o app verifica novas versões no GitHub, mostra as notas da versão e instala a atualização com um clique. Cada atualização é verificada pela assinatura de código do desenvolvedor antes de ser instalada. Você também pode usar *YUCE Cleaner › Verificar Atualizações…* ou desativar a verificação automática no mesmo menu.

## Download

1. Baixe o arquivo **`YUCE-Cleaner-x.y.z.dmg`** mais recente na [página de Releases](https://github.com/bariscagriyuce/mac-cleaner/releases/latest).
2. Abra o DMG e arraste o **YUCE Cleaner** para a pasta **Aplicativos**.
3. Abra o app pela pasta Aplicativos ou pelo Launchpad.

O app é assinado com Developer ID e notarizado pela Apple, então abre sem avisos de segurança. Funciona em Macs com Apple silicon e Intel (macOS 14 ou posterior).

## Requisitos

- macOS 14 Sonoma ou posterior (Apple silicon ou Intel)
- Xcode ou as Ferramentas de Linha de Comando do Xcode (`xcode-select --install`) para compilar

## Compilar e executar

```bash
git clone https://github.com/bariscagriyuce/mac-cleaner.git
cd mac-cleaner
./build.sh
open "YUCE Cleaner.app"
```

Depois, você pode arrastar o `YUCE Cleaner.app` para a pasta Aplicativos.

Para gerar você mesmo um DMG assinado e notarizado, veja os comentários no início do `release.sh`.

## Acesso Total ao Disco (recomendado)

Alguns locais, como a Lixeira, os dados do Mail e os backups do iPhone, são protegidos pelo macOS. Para analisá-los:

1. Abra **Ajustes do Sistema › Privacidade e Segurança › Acesso Total ao Disco**
2. Clique em **+** e adicione o **YUCE Cleaner**
3. Feche e abra o app novamente

O botão *Abrir Ajustes* no app leva você direto para lá.

## Idioma

O idioma é escolhido a partir dos idiomas preferidos do macOS (Ajustes do Sistema › Geral › Idioma e Região):

| Idioma do sistema | Idioma do app |
|---|---|
| Turco | Turco |
| Português (qualquer região) | Português do Brasil |
| Inglês | Inglês |
| Qualquer outro | Inglês |

Você também pode escolher um idioma só para este app em **Ajustes do Sistema › Geral › Idioma e Região › Aplicativos**.

## Estrutura do projeto

```
Sources/YUCECleaner.swift    App, análise, lógica de exclusão e telas SwiftUI
Sources/Updater.swift        Verificação e instalação de atualizações (GitHub Releases)
Sources/Localization.swift   Detecção de idioma e traduções (tr, pt-BR)
build.sh                     Compila o pacote .app (universal) com swiftc
release.sh                   Assina, notariza e gera o DMG
```

Para adicionar um idioma, inclua um dicionário em `Localization.swift`. As chaves são os textos em inglês.

## Aviso

Apagar arquivos é sempre por sua conta e risco. Leia as descrições das categorias, prefira *Mover para a Lixeira* e mantenha backups dos dados importantes.

Mac e macOS são marcas registradas da Apple Inc. O YUCE Cleaner é um app independente, sem vínculo com a Apple e não endossado por ela.
