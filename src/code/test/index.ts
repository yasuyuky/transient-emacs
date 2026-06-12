import * as path from 'path';
import Mocha = require('mocha');
import * as glob from 'glob';
import * as vscode from 'vscode';

export function run(): Promise<void> {
  // Create the mocha test
  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
  });

  const testsRoot = path.resolve(__dirname, '..');

  return new Promise(async (c, e) => {
    const files = await glob.glob('**/**.test.js', { cwd: testsRoot });
    files.forEach(f => mocha.addFile(path.resolve(testsRoot, f)));

    try {
      // Run the mocha test
      mocha.run(async (failures: number) => {
        await vscode.commands.executeCommand('workbench.action.closeWindow');
        failures > 0 ? e(new Error(`${failures} tests failed.`)) : c();
      });
    } catch (err) {
      e(err);
    }
  });
}
