// Inline code that is a command line (`make clean`, `sudo dnf install helix`,
// `gcc -c main.c -o main.o`) gets the colors of a terminal, like in the slides
// (slides/src/terminal.typ, highlight-shell): the command, the options, the
// strings, the variables and the operators. Other inline code is left as it is.

// the programs whose command lines are highlighted
const PROGRAMS = new Set([
  "make", "gcc", "clang", "cc", "touch", "ls", "cat", "rm", "cp", "mv", "mkdir", "rmdir", "cd", "pwd",
  "echo", "printf", "gdb", "lldb", "objdump", "nm", "ldd", "file", "ar", "strip", "readelf", "size",
  "vim", "nvim", "hx", "emacs", "nano", "code", "zed", "clangd", "bear",
  "git", "less", "more", "sudo", "su", "apt", "dnf", "snap", "flatpak", "curl", "wget", "ssh", "ssh-keygen",
  "wc", "grep", "head", "tail", "sort", "uniq", "cut", "tr", "sed", "awk", "find", "which", "man", "od",
  "bash", "sh", "python3", "java", "javac", "node", "strace", "stat", "chmod", "chown", "chgrp", "umask",
  "ps", "pstree", "pgrep", "kill", "killall", "top", "htop", "jobs", "fg", "bg", "sleep", "tee", "tree",
  "id", "whoami", "groups", "getent", "passwd", "useradd", "usermod", "userdel", "groupadd", "gpasswd",
  "export", "source", "env", "type", "history", "readlink", "ln", "du", "df", "tar", "xargs",
]);
const SUDO = new Set(["sudo", "doas"]);
const SUDO_ARG_OPTIONS = new Set(["-u", "-g", "-U", "-C", "-D", "-p", "-r", "-t", "-T"]);
const SEPARATORS = new Set(["&&", "||", ";", "|", "&"]);
const REDIRECTIONS = new Set([">>", ">", "<<", "<", ">&", "&>", "&>>", "<&", ">|"]);
const TOKEN = /<[A-Za-z][A-Za-z0-9_-]*>|\\.|"[^"]*"|'[^']*'|\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_]*=("[^"]*"|'[^']*'|[^ \t$]*)|\|\||&&|[|;&<>]+|#.*|--?[A-Za-z0-9][A-Za-z0-9._=-]*|[ \t]+|\$|[^ \t$\\]+|\\/g;

function isCommand(text) {
  const t = text.startsWith("$ ") ? text.slice(2) : text;
  const first = t.split(" ")[0];
  return PROGRAMS.has(first) || /^\.\/\S/.test(t);
}

const span = (cls, value) => ({
  type: "element",
  tagName: "span",
  properties: { className: [cls] },
  children: [{ type: "text", value }],
});
const plain = (value) => ({ type: "text", value });

function highlight(line) {
  const out = [];
  let rest = line;
  if (rest.startsWith("$ ")) {
    out.push(span("sh-prompt", "$"), plain(" "));
    rest = rest.slice(2);
  }
  let expectCommand = true, afterRedirect = false, inComment = false, afterSudo = false, sudoArg = false;
  for (const m of rest.matchAll(TOKEN)) {
    const t = m[0];
    if (inComment) out.push(span("sh-comment", t));
    else if (/^<[A-Za-z][A-Za-z0-9_-]*>$/.test(t)) {
      // a placeholder, like <FILE>: the student writes a value in its place
      out.push(span("sh-placeholder", t));
      if (expectCommand) { expectCommand = false; afterSudo = false; }
      afterRedirect = false;
    }
    else if (t.trim() === "") out.push(plain(t));
    else if (t.startsWith("#")) { inComment = true; out.push(span("sh-comment", t)); }
    else if (t.length === 2 && t.startsWith("\\")) { out.push(plain(t)); expectCommand = false; }
    else if (SEPARATORS.has(t)) { out.push(span("sh-op", t)); expectCommand = true; }
    else if (REDIRECTIONS.has(t) || /^[0-9]+(>>|>|<|>&|<&)$/.test(t)) { out.push(span("sh-op", t)); afterRedirect = true; }
    else if (afterRedirect) {
      out.push(/^["']/.test(t) ? span("sh-str", t) : t.startsWith("$") ? span("sh-var", t) : plain(t));
      afterRedirect = false;
    } else if (expectCommand && /^[A-Za-z_][A-Za-z0-9_]*=/.test(t)) {
      const eq = t.indexOf("=");
      out.push(span("sh-var", t.slice(0, eq)), plain("="));
      const value = t.slice(eq + 1);
      if (value) out.push(/^["']/.test(value) ? span("sh-str", value) : plain(value));
    } else if (expectCommand && SUDO.has(t)) { out.push(span("sh-sudo", t)); afterSudo = true; }
    else if (expectCommand && afterSudo && sudoArg) { out.push(plain(t)); sudoArg = false; }
    else if (expectCommand && afterSudo && t.startsWith("-")) { out.push(span("sh-flag", t)); sudoArg = SUDO_ARG_OPTIONS.has(t); }
    else if (expectCommand) { out.push(span("sh-cmd", t)); expectCommand = false; afterSudo = false; }
    else if (/^["']/.test(t)) out.push(span("sh-str", t));
    else if (t.startsWith("$")) out.push(span("sh-var", t));
    else if (t.startsWith("-")) out.push(span("sh-flag", t));
    else if (/^[|;&<>]+$/.test(t)) out.push(span("sh-op", t));
    else out.push(plain(t));
  }
  return out;
}

function walk(node, parent) {
  if (node.type === "element" && node.tagName === "code" && !(parent && parent.tagName === "pre")) {
    const kids = node.children || [];
    if (kids.length === 1 && kids[0].type === "text" && isCommand(kids[0].value)) {
      node.children = highlight(kids[0].value);
      const cls = node.properties.className || [];
      node.properties.className = [...(Array.isArray(cls) ? cls : [cls]), "sh-inline"];
    }
    return;
  }
  for (const child of node.children || []) walk(child, node);
}

export default function rehypeInlineShell() {
  return (tree) => walk(tree, null);
}
