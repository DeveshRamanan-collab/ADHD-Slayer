#!/usr/bin/env node
import { App } from 'aws-cdk-lib/core';
import { buildFocusApp } from '../lib/app';
import { loadConfigs, sourcesFromNode } from '../lib/config';

const app = new App();
buildFocusApp(app, loadConfigs(sourcesFromNode(app.node)));
