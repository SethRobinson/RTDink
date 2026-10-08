// Run with: node tests/html5_loader.cjs (no browser or npm dependencies).
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

async function main() {
    const template = fs.readFileSync(path.join(__dirname, '../html5/CustomMain4-3AspectRatioTemplate.html'), 'utf8');
    const helper = fs.readFileSync(path.join(__dirname, '../html5/DinkFileTransfer.js'), 'utf8');
    const input = {files: [], value: ''};
    const progressFill = {style: {}};
    const progress = {style: {}, querySelector: () => progressFill};
    const spinner = {style: {}};
    const loadingText = {textContent: ''};
    const loader = {
        style: {},
        querySelector: selector => ({'.progress': progress, '.spinner': spinner, '.loadingtext': loadingText})[selector]
    };
    const messages = [];
    const writes = [];
    const readers = [];
    const alerts = [];
    const downloads = [];
    const bytes = new Uint8Array([9, 0, 255, 1, 8]);
    const context = vm.createContext({
        console: {log() {}, error() {}},
        Uint8Array, Blob,
        loader,
        navigator: {userAgent: 'Chrome'},
        // Keep FileSaver itself untouched; intercept only its output for assertions.
        saveAs: (blob, name) => downloads.push({blob, name}),
        alert: text => alerts.push(text),
        FileReader: class {
            constructor() { readers.push(this); }
            readAsArrayBuffer(file) { this.file = file; }
        },
        FS: {
            writeFile: (name, data) => writes.push({name, data}),
            // Test a view with a nonzero offset, not just a whole ArrayBuffer.
            readFile: () => bytes.subarray(1, 4)
        },
        window: {addEventListener() {}},
        document: {
            getElementById: id => ({loader, uploader: input, canvas: {}})[id],
            createElement: () => ({}),
            body: {appendChild() {}}
        }
    });
    for (const match of template.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/g)) {
        if (!/\bsrc\s*=/.test(match[1])) vm.runInContext(match[2], context);
    }
    context.Module.ccall = (...args) => messages.push(args);
    const originalModule = context.Module;
    vm.runInContext(helper, context);
    assert.equal(context.Module, originalModule, 'File helpers must not replace Module');

    for (const status of ['Downloading...', 'Downloading data...', 'Downloading data... (25/100)', 'Running...', '']) {
        context.Module.setStatus(status);
        assert.notEqual(loader.style.display, 'none', `Loader hidden during ${status}`);
        if (status.includes('(25/100)')) {
            assert.equal(progressFill.style.transform, 'scaleX(0.25)');
            assert.equal(loadingText.textContent, 'Loading... 25%');
        }
    }
    context.Module.setStatus('Downloading data... (0/0)');
    assert.equal(spinner.style.display, 'block');
    context.Module.onRuntimeInitialized();
    assert.equal(loader.style.display, 'none');
    assert.equal(messages[0][0], 'mainf');
    context.Module.setStatus('');
    assert.equal(loader.style.display, 'none', 'Late status must not reopen loader');

    context.previewFile();
    assert.equal(readers.length, 0, 'Cancelled picker must do nothing');
    const file = {name: 'save2 (2).dat'};
    input.files = [file];
    input.value = 'selected';
    context.previewFile();
    assert.equal(input.value, '', 'Same filename can be selected again');
    readers[0].result = bytes.buffer;
    readers[0].onload();
    assert.equal(writes[0].name, '/proton_temp.tmp');
    assert.deepEqual([...writes[0].data], [...bytes]);
    assert.equal(messages[1][0], 'PROTON_GUIMessage');
    assert.deepEqual([...messages[1][3]], [53, 0, file.name]);

    context.previewFile();
    readers[1].error = new Error('Read failure');
    readers[1].onerror();
    assert.equal(alerts.length, 1);
    assert.equal(writes.length, 1, 'Read failure must not import stale bytes');
    assert.equal(messages.length, 2);

    context.saveFileFromMemoryFSToDisk('/save.dat', 'save.dat');
    assert.equal(downloads[0].name, 'save.dat');
    assert.deepEqual([...new Uint8Array(await downloads[0].blob.arrayBuffer())], [0, 255, 1]);
    context.navigator.userAgent = 'Version/18.0 Safari/605.1.15';
    context.saveFileFromMemoryFSToDisk('/save.dat', 'save.dat');
    assert.equal(downloads[1].blob.type, 'application/octet-stream');
    console.log('PASS: loader status sequence, runtime handoff, cancelled/failed upload, filename/bytes, download bytes and Safari MIME');
}

main().catch(error => { console.error(error); process.exitCode = 1; });
