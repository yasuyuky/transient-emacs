//
// Note: This example test is leveraging the Mocha test framework.
// Please refer to their documentation on https://mochajs.org/ for help.
//

// The module 'assert' provides assertion methods from node
import * as assert from 'assert';

// You can import and use all API from the 'vscode' module
// as well as import your extension to test it
import * as vscode from 'vscode';
import { Position, Selection } from 'vscode';

async function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function move(editor: vscode.TextEditor, ps: Position[]) {
  editor.selections = ps.map(p => new Selection(p, p));
}

// Defines a Mocha test suite to group tests of similar kind together
suite('Extension Tests', async () => {
  // Defines a Mocha unit test
  await test('transient.kill', async () => {
    let doc = await vscode.workspace.openTextDocument({
      content: 'foo bar\nbaz\n'
    });
    let editor = await vscode.window.showTextDocument(doc);
    move(editor, [new Position(0, 0)]);
    await vscode.commands.executeCommand('transient.kill');
    await sleep(150);
    assert.equal('\nbaz\n', editor.document.getText());
    await vscode.commands.executeCommand('transient.kill');
    await sleep(150);
    assert.equal('baz\n', editor.document.getText());
  });

  await test('transient.kill with multi cursor', async () => {
    let doc = await vscode.workspace.openTextDocument({
      content: 'foo bar\nbaz\n'
    });
    let editor = await vscode.window.showTextDocument(doc);
    move(editor, [new Position(0, 0), new Position(1,0)]);
    await vscode.commands.executeCommand('transient.kill');
    await sleep(150);
    assert.equal('\n\n', editor.document.getText());
    await vscode.commands.executeCommand('transient.kill');
    await sleep(150);
    assert.equal('', editor.document.getText());
  });

});
