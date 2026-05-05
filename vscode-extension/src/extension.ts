import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(_context: vscode.ExtensionContext): void {
    const command = process.env['ANAKINS_DTLS_BIN'] ?? 'anakins-dtls';
    const serverOptions: ServerOptions = { command };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'dts' }],
    };
    client = new LanguageClient(
        'anakins-dtls',
        'Device Tree Language Server',
        serverOptions,
        clientOptions,
    );
    client.start();
}

export function deactivate(): Thenable<void> | undefined {
    return client?.stop();
}
