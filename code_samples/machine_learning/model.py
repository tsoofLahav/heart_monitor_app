"""Two-branch 1D CNN for PPG quality classification."""

from __future__ import annotations

import torch
import torch.nn as nn

VALID_MODES = ("waveform", "peaks", "both")


class ConvBlock(nn.Module):
    def __init__(self, in_ch: int, out_ch: int, kernel_size: int = 7, pool: int = 2):
        super().__init__()
        padding = kernel_size // 2
        self.block = nn.Sequential(
            nn.Conv1d(in_ch, out_ch, kernel_size=kernel_size, padding=padding),
            nn.BatchNorm1d(out_ch),
            nn.ReLU(inplace=True),
            nn.MaxPool1d(pool),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.block(x)


class WaveformBranch(nn.Module):
    def __init__(self, embedding_dim: int = 64):
        super().__init__()
        self.encoder = nn.Sequential(
            ConvBlock(1, 32, kernel_size=7, pool=2),
            ConvBlock(32, 64, kernel_size=5, pool=2),
            ConvBlock(64, 128, kernel_size=5, pool=2),
            nn.AdaptiveAvgPool1d(1),
        )
        self.proj = nn.Linear(128, embedding_dim)

    def forward(self, waveform: torch.Tensor) -> torch.Tensor:
        x = self.encoder(waveform).squeeze(-1)
        return self.proj(x)


class PeakBranch(nn.Module):
    def __init__(self, rr_dim: int = 5, embedding_dim: int = 64):
        super().__init__()
        self.mask_encoder = nn.Sequential(
            ConvBlock(1, 16, kernel_size=5, pool=2),
            ConvBlock(16, 32, kernel_size=5, pool=2),
            ConvBlock(32, 64, kernel_size=3, pool=2),
            nn.AdaptiveAvgPool1d(1),
        )
        self.mask_proj = nn.Linear(64, 48)
        self.rr_mlp = nn.Sequential(
            nn.Linear(rr_dim, 32),
            nn.ReLU(inplace=True),
            nn.Linear(32, 16),
            nn.ReLU(inplace=True),
        )
        self.fuse = nn.Sequential(
            nn.Linear(48 + 16, embedding_dim),
            nn.ReLU(inplace=True),
        )

    def forward(self, peak_mask: torch.Tensor, rr_features: torch.Tensor) -> torch.Tensor:
        mask_emb = self.mask_proj(self.mask_encoder(peak_mask).squeeze(-1))
        rr_emb = self.rr_mlp(rr_features)
        return self.fuse(torch.cat([mask_emb, rr_emb], dim=1))


class TwoBranchCNN(nn.Module):
    def __init__(self, mode: str = "both", dropout: float = 0.3):
        super().__init__()
        if mode not in VALID_MODES:
            raise ValueError(f"mode must be one of {VALID_MODES}, got {mode!r}")

        self.mode = mode
        self.waveform_branch = WaveformBranch(embedding_dim=64)
        self.peak_branch = PeakBranch(rr_dim=5, embedding_dim=64)

        if mode == "waveform":
            classifier_in = 64
        elif mode == "peaks":
            classifier_in = 64
        else:
            classifier_in = 128

        self.classifier = nn.Sequential(
            nn.Linear(classifier_in, 64),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout),
            nn.Linear(64, 1),
        )

    def forward(
        self,
        waveform: torch.Tensor,
        peak_mask: torch.Tensor,
        rr_features: torch.Tensor,
    ) -> torch.Tensor:
        if self.mode == "waveform":
            emb = self.waveform_branch(waveform)
        elif self.mode == "peaks":
            emb = self.peak_branch(peak_mask, rr_features)
        else:
            w_emb = self.waveform_branch(waveform)
            p_emb = self.peak_branch(peak_mask, rr_features)
            emb = torch.cat([w_emb, p_emb], dim=1)

        return self.classifier(emb).squeeze(-1)
