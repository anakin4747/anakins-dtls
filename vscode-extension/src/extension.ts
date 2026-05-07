import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext): void {
    const command = process.env['ANAKINS_DTLS_BIN'] ?? 'anakins-dtls';

    const outputChannel = vscode.window.createOutputChannel('anakins-dtls');
    outputChannel.appendLine(`Starting anakins-dtls: ${command}`);

    const serverOptions: ServerOptions = { command };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'dts' }],
        outputChannel,
    };

    client = new LanguageClient(
        'anakins-dtls',
        'Device Tree Language Server',
        serverOptions,
        clientOptions,
    );

    client.start().catch((err: unknown) => {
        outputChannel.appendLine(`Failed to start: ${err}`);
        vscode.window.showErrorMessage(`anakins-dtls failed to start: ${err}`);
    });

    context.subscriptions.push({ dispose: () => client?.stop() });
}

export function deactivate(): Thenable<void> | undefined {
    return client?.stop();
}
