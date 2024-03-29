import * as path from 'path';
import { runTests } from '@vscode/test-electron';

async function go() {
  const extensionDevelopmentPath = path.resolve(__dirname, '../../..');
  const extensionTestsPath = path.resolve(__dirname, './');
  await runTests({ extensionDevelopmentPath, extensionTestsPath }).catch(_ => process.exit(1));
}

go();
