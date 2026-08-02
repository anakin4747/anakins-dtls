import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
  TransportKind,
} from "vscode-languageclient/node";

let client: LanguageClient | undefined;

export function activate(): void {
  const serverOptions: ServerOptions = {
    command: "anakins-dtls",
    transport: TransportKind.stdio,
  };
  const clientOptions: LanguageClientOptions = {
    documentSelector: [
      { language: "devicetree", scheme: "file" },
    ],
  };

  client = new LanguageClient(
    "anakins-dtls",
    "Anakin's Devicetree Language Server",
    serverOptions,
    clientOptions,
  );
  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
