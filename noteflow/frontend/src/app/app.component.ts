import { Component } from '@angular/core';
import { NotesComponent } from './components/notes/notes.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [NotesComponent],
  template: `<app-notes></app-notes>`
})
export class AppComponent {}
