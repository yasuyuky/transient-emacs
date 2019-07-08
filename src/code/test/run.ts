import * as path from 'path';
import { runTests } from 'vscode-test';

async function go() {
  const extensionPath = path.resolve(__dirname, '../../..');
  const testRunnerPath = path.resolve(__dirname, './');
  const testWorkspace = path.resolve(__dirname, '../../..');
  await runTests({ extensionPath, testRunnerPath, testWorkspace }).catch(_ => process.exit(1));
}

go();
