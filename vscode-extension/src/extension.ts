import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    Trace,
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext): void {
    const command = process.env['ANAKINS_DTLS_BIN'] ?? 'anakins-dtls';

    const outputChannel = vscode.window.createOutputChannel('anakins-dtls');
    outputChannel.appendLine(`Starting anakins-dtls: ${command}`);
    outputChannel.show();

    const serverOptions: ServerOptions = { command };
    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'dts' }],
        outputChannel,
        traceOutputChannel: outputChannel,
        initializationFailedHandler: (err) => {
            outputChannel.appendLine(`Initialization failed: ${err}`);
            return false;
        },
        errorHandler: {
            error: (err, msg) => {
                outputChannel.appendLine(`Error: ${err} msg: ${JSON.stringify(msg)}`);
                return { action: 1 };
            },
            closed: () => {
                outputChannel.appendLine('Connection closed');
                return { action: 2 };
            },
        },
    };

    client = new LanguageClient(
        'anakins-dtls',
        'Device Tree Language Server',
        serverOptions,
        clientOptions,
    );

    client.setTrace(Trace.Verbose);

    client.onDidChangeState((e) => {
        outputChannel.appendLine(`State: ${e.oldState} -> ${e.newState}`);
    });

    // Log all outgoing requests
    client.middleware = {
        provideImplementation: async (doc, pos, token, next) => {
            outputChannel.appendLine(`implementation: line=${pos.line} char=${pos.character} uri=${doc.uri}`);
            const result = await next(doc, pos, token);
            outputChannel.appendLine(`implementation result: ${JSON.stringify(result)}`);
            return result;
        },
        provideDefinition: async (doc, pos, token, next) => {
            outputChannel.appendLine(`definition: line=${pos.line} char=${pos.character} uri=${doc.uri}`);
            const result = await next(doc, pos, token);
            outputChannel.appendLine(`definition result: ${JSON.stringify(result)}`);
            return result;
        },
    };

    client.start().catch((err: unknown) => {
        outputChannel.appendLine(`Failed to start: ${err}`);
        vscode.window.showErrorMessage(`anakins-dtls failed to start: ${err}`);
    });

    context.subscriptions.push({ dispose: () => client?.stop() });
}

export function deactivate(): Thenable<void> | undefined {
    return client?.stop();
}
