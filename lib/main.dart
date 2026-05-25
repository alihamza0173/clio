import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TerminalApp());
}

class TerminalApp extends StatelessWidget {
  const TerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'clio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF238636),
          surface: Color(0xFF161B22),
        ),
      ),
      home: const TerminalHome(),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────

class TerminalLine {
  final String text;
  final LineType type;

  const TerminalLine(this.text, this.type);
}

enum LineType { prompt, stdout, stderr, info }

class TerminalTab {
  String title;
  String workingDir;
  final List<TerminalLine> lines;
  Process? runningProcess;

  TerminalTab({
    required this.title,
    required this.workingDir,
    List<TerminalLine>? lines,
  }) : lines = lines ?? [];
}

// ─── Home ─────────────────────────────────────────────────────────

class TerminalHome extends StatefulWidget {
  const TerminalHome({super.key});

  @override
  State<TerminalHome> createState() => _TerminalHomeState();
}

class _TerminalHomeState extends State<TerminalHome> {
  final List<TerminalTab> _tabs = [
    TerminalTab(
      title: 'Terminal 1',
      workingDir: Platform.environment['HOME'] ?? '~',
    ),
  ];
  int _activeTab = 0;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<String> _history = [];
  int _historyIndex = -1;

  TerminalTab get _current => _tabs[_activeTab];

  // ── Snippets shown in sidebar ──
  final List<String> _snippets = [
    'ls -la',
    'pwd',
    'git status',
    'git log --oneline -10',
    'dart pub get',
    'flutter run',
    'echo \$PATH',
    'env | grep HOME',
    'cat ~/.zshrc',
  ];

  @override
  void initState() {
    super.initState();
    _loadShellPath();
    _addLine('Welcome to clio', LineType.info);
    _addLine(
      'Runs commands via zsh login shell — loads ~/.zshrc & ~/.zshenv',
      LineType.info,
    );
    _addLine('', LineType.info);
  }

  void _addLine(String text, LineType type) {
    setState(() {
      _current.lines.add(TerminalLine(text, type));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Key: run via `zsh -l -c` so all rc files are sourced ──
  Future<void> _runCommand(String cmd) async {
    if (cmd.trim().isEmpty) return;

    _history.insert(0, cmd);
    _historyIndex = -1;
    _inputController.clear();

    final promptLine = '${_current.workingDir} ❯ $cmd';
    _addLine(promptLine, LineType.prompt);

    // Handle built-in `cd`
    if (cmd.trim().startsWith('cd')) {
      final parts = cmd.trim().split(RegExp(r'\s+'));
      final targetRaw = parts.length > 1
          ? parts[1]
          : (Platform.environment['HOME'] ?? '~');
      final target = targetRaw.replaceFirst(
        '~',
        Platform.environment['HOME'] ?? '',
      );
      try {
        final dir = Directory(target);
        if (await dir.exists()) {
          _current.workingDir = dir.path;
          _addLine('', LineType.stdout);
        } else {
          _addLine('cd: no such file or directory: $target', LineType.stderr);
        }
      } catch (e) {
        _addLine('cd: $e', LineType.stderr);
      }
      return;
    }

    if (cmd.trim() == 'clear') {
      setState(() => _current.lines.clear());
      return;
    }

    try {
      // Use `zsh -l -c` → login shell → loads ~/.zshenv, ~/.zprofile, ~/.zshrc
      final process = await Process.start(
        'zsh',
        ['-l', '-c', cmd],
        workingDirectory: _current.workingDir,
        environment: {
          ...Platform.environment,
          'PATH': _envPath, // ← use the shell-loaded PATH
          'TERM': 'xterm-256color',
        },
      );

      _current.runningProcess = process;

      // Stream stdout
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _addLine(line, LineType.stdout));

      // Stream stderr
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _addLine(line, LineType.stderr));

      final exitCode = await process.exitCode;
      _current.runningProcess = null;

      if (exitCode != 0) {
        _addLine('[exit code: $exitCode]', LineType.info);
      }
    } on ProcessException catch (e) {
      _addLine('Error: ${e.message}', LineType.stderr);
    } catch (e) {
      _addLine('Error: $e', LineType.stderr);
    }
  }

  void _killCurrent() {
    _current.runningProcess?.kill(ProcessSignal.sigint);
  }

  void _addTab() {
    setState(() {
      _tabs.add(
        TerminalTab(
          title: 'Terminal ${_tabs.length + 1}',
          workingDir: Platform.environment['HOME'] ?? '~',
        ),
      );
      _activeTab = _tabs.length - 1;
    });
  }

  void _closeTab(int i) {
    if (_tabs.length == 1) return;
    setState(() {
      _tabs[i].runningProcess?.kill();
      _tabs.removeAt(i);
      if (_activeTab >= _tabs.length) _activeTab = _tabs.length - 1;
    });
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildOutput()),
                      _buildInputBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──
  Widget _buildTabBar() {
    return Container(
      height: 34,
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          ...List.generate(_tabs.length, (i) {
            final active = i == _activeTab;
            return GestureDetector(
              onTap: () => setState(() => _activeTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF0D1117) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? const Color(0xFF238636)
                          : Colors.transparent,
                      width: 2,
                    ),
                    right: const BorderSide(
                      color: Color(0xFF21262D),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _tabs[i].title,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF8B949E),
                        fontSize: 12,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    if (_tabs.length > 1) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _closeTab(i),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Color(0xFF8B949E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF8B949E)),
            onPressed: _addTab,
            splashRadius: 14,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.stop_circle_outlined,
              size: 16,
              color: Color(0xFFF78166),
            ),
            tooltip: 'Kill process (Ctrl+C)',
            onPressed: _killCurrent,
            splashRadius: 14,
          ),
        ],
      ),
    );
  }

  // ── Sidebar ──
  Widget _buildSidebar() {
    return Container(
      width: 160,
      color: const Color(0xFF161B22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              'SNIPPETS',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                letterSpacing: 1.2,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          ..._snippets.map((s) => _sidebarItem(s)),
          const Divider(color: Color(0xFF21262D), thickness: 0.5, height: 20),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
            child: Text(
              'HISTORY',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                letterSpacing: 1.2,
                fontFamily: 'JetBrains Mono',
              ),
            ),
          ),
          ..._history.take(8).map((h) => _sidebarItem(h)),
        ],
      ),
    );
  }

  Widget _sidebarItem(String cmd) {
    return InkWell(
      onTap: () {
        _inputController.text = cmd;
        _focusNode.requestFocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          cmd,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFC9D1D9),
            fontSize: 11,
            fontFamily: 'JetBrains Mono',
          ),
        ),
      ),
    );
  }

  // ── Output area ──
  Widget _buildOutput() {
    return Container(
      color: const Color(0xFF0D1117),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(14),
        itemCount: _current.lines.length,
        itemBuilder: (_, i) {
          final line = _current.lines[i];
          return SelectableText(
            line.text,
            style: TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              height: 1.7,
              color: _lineColor(line.type),
            ),
          );
        },
      ),
    );
  }

  Color _lineColor(LineType t) {
    switch (t) {
      case LineType.prompt:
        return const Color(0xFF7EE787);
      case LineType.stdout:
        return const Color(0xFFE6EDF3);
      case LineType.stderr:
        return const Color(0xFFF78166);
      case LineType.info:
        return const Color(0xFF8B949E);
    }
  }

  // ── Input bar ──
  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(top: BorderSide(color: Color(0xFF21262D), width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text(
            '❯ ',
            style: TextStyle(
              color: Color(0xFFF78166),
              fontFamily: 'JetBrains Mono',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_history.isNotEmpty &&
                        _historyIndex < _history.length - 1) {
                      _historyIndex++;
                      _inputController.text = _history[_historyIndex];
                      _inputController.selection = TextSelection.collapsed(
                        offset: _inputController.text.length,
                      );
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_historyIndex > 0) {
                      _historyIndex--;
                      _inputController.text = _history[_historyIndex];
                    } else {
                      _historyIndex = -1;
                      _inputController.clear();
                    }
                  }
                }
              },
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 13,
                  color: Color(0xFFE6EDF3),
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a command...',
                  hintStyle: TextStyle(color: Color(0xFF484F58)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _runCommand,
                cursorColor: const Color(0xFFE6EDF3),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _runCommand(_inputController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF238636),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Run ↵'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    for (final tab in _tabs) {
      tab.runningProcess?.kill();
    }
    super.dispose();
  }
}

Future<void> _loadShellPath() async {
  try {
    final result = await Process.run('zsh', ['-l', '-c', 'echo \$PATH']);
    if (result.exitCode == 0) {
      final shellPath = (result.stdout as String).trim();
      // Merge with current env PATH
      final current = Platform.environment['PATH'] ?? '';
      final merged = '$shellPath:$current';
      // Now pass this merged PATH in every Process.start call
      _envPath = merged;
    }
  } catch (_) {}
}

String _envPath = Platform.environment['PATH'] ?? '';
