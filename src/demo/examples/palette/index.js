import { detached, div } from 'hexagon-js';

export default () => [
  detached('h3').text('Text Classes'),
  div('hx-group hx-horizontal').add([
    div('hx-section demo-palette-example-text hx-text-default').text('hx-text-default'),
    div('hx-section demo-palette-example-text hx-text-action').text('hx-text-action'),
    div('hx-section demo-palette-example-text hx-text-positive').text('hx-text-positive'),
    div('hx-section demo-palette-example-text hx-text-warning').text('hx-text-warning'),
    div('hx-section demo-palette-example-text hx-text-negative').text('hx-text-negative'),
    div('hx-section demo-palette-example-text hx-text-info').text('hx-text-info'),
    div('hx-section demo-palette-example-text hx-text-complement').text('hx-text-complement'),
    div('hx-section demo-palette-example-text hx-text-contrast').text('hx-text-contrast'),
    div('hx-section demo-palette-example-text hx-text-disabled').text('hx-text-disabled'),
  ]),
  detached('h3').text('Background Classes'),
  div('hx-group hx-horizontal').add([
    div('hx-section demo-palette-example-background hx-background-default').text('hx-background-default'),
    div('hx-section demo-palette-example-background hx-background-action').text('hx-background-action'),
    div('hx-section demo-palette-example-background hx-background-positive').text('hx-background-positive'),
    div('hx-section demo-palette-example-background hx-background-warning').text('hx-background-warning'),
    div('hx-section demo-palette-example-background hx-background-negative').text('hx-background-negative'),
    div('hx-section demo-palette-example-background hx-background-info').text('hx-background-info'),
    div('hx-section demo-palette-example-background hx-background-complement').text('hx-background-complement'),
    div('hx-section demo-palette-example-background hx-background-contrast').text('hx-background-contrast'),
    div('hx-section demo-palette-example-background hx-background-disabled').text('hx-background-disabled'),
  ]),
  detached('h3').text('Border Classes'),
  div('hx-group hx-horizontal').add([
    div('hx-section demo-palette-example-border hx-border-default').text('hx-border-default'),
    div('hx-section demo-palette-example-border hx-border-action').text('hx-border-action'),
    div('hx-section demo-palette-example-border hx-border-positive').text('hx-border-positive'),
    div('hx-section demo-palette-example-border hx-border-warning').text('hx-border-warning'),
    div('hx-section demo-palette-example-border hx-border-negative').text('hx-border-negative'),
    div('hx-section demo-palette-example-border hx-border-info').text('hx-border-info'),
    div('hx-section demo-palette-example-border hx-border-complement').text('hx-border-complement'),
    div('hx-section demo-palette-example-border hx-border-contrast').text('hx-border-contrast'),
    div('hx-section demo-palette-example-border hx-border-disabled').text('hx-border-disabled'),
  ]),
];
