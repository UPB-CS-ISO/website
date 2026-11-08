// Inline code that plugins/rehype-inline-shell.mjs colored has <span> children:
// the original component would take it for a code block, so render it inline here.
import React from 'react';
import Code from '@theme-original/MDXComponents/Code';

export default function CodeWrapper(props) {
  const cls = typeof props.className === 'string' ? props.className.split(' ') : [];
  if (cls.includes('sh-inline')) {
    return <code {...props} />;
  }
  return <Code {...props} />;
}
