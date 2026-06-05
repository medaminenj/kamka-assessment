import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NoteService } from '../../services/note.service';
import { Note } from '../../models/note.model';

@Component({
  selector: 'app-notes',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './notes.component.html',
  styleUrls: ['./notes.component.scss']
})
export class NotesComponent implements OnInit {
  notes: Note[] = [];
  isLoading = false;
  errorMessage = '';
  successMessage = '';

  // Form state
  showForm = false;
  isEditing = false;
  editingId: number | null = null;
  formTitle = '';
  formContent = '';
  formSubmitting = false;

  // Delete confirmation
  deletingId: number | null = null;

  constructor(private noteService: NoteService) {}

  ngOnInit(): void {
    this.loadNotes();
  }

  loadNotes(): void {
    this.isLoading = true;
    this.errorMessage = '';
    this.noteService.getAllNotes().subscribe({
      next: (notes) => {
        this.notes = notes;
        this.isLoading = false;
      },
      error: (err) => {
        this.errorMessage = 'Failed to load notes. Is the backend running?';
        this.isLoading = false;
        console.error(err);
      }
    });
  }

  openCreateForm(): void {
    this.showForm = true;
    this.isEditing = false;
    this.editingId = null;
    this.formTitle = '';
    this.formContent = '';
  }

  openEditForm(note: Note): void {
    this.showForm = true;
    this.isEditing = true;
    this.editingId = note.id!;
    this.formTitle = note.title;
    this.formContent = note.content;
  }

  cancelForm(): void {
    this.showForm = false;
    this.formTitle = '';
    this.formContent = '';
    this.isEditing = false;
    this.editingId = null;
  }

  submitForm(): void {
    if (!this.formTitle.trim()) return;

    this.formSubmitting = true;
    const payload = { title: this.formTitle.trim(), content: this.formContent.trim() };

    const request = this.isEditing
      ? this.noteService.updateNote(this.editingId!, payload)
      : this.noteService.createNote(payload);

    request.subscribe({
      next: () => {
        this.formSubmitting = false;
        this.cancelForm();
        this.showSuccess(this.isEditing ? 'Note updated!' : 'Note created!');
        this.loadNotes();
      },
      error: (err) => {
        this.formSubmitting = false;
        this.errorMessage = 'Failed to save note.';
        console.error(err);
      }
    });
  }

  confirmDelete(id: number): void {
    this.deletingId = id;
  }

  cancelDelete(): void {
    this.deletingId = null;
  }

  deleteNote(id: number): void {
    this.noteService.deleteNote(id).subscribe({
      next: () => {
        this.deletingId = null;
        this.showSuccess('Note deleted.');
        this.loadNotes();
      },
      error: (err) => {
        this.errorMessage = 'Failed to delete note.';
        console.error(err);
      }
    });
  }

  showSuccess(msg: string): void {
    this.successMessage = msg;
    setTimeout(() => (this.successMessage = ''), 3000);
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
      + ' · ' + d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  }
}
