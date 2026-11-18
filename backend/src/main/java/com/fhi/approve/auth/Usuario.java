package com.fhi.approve.auth;

import java.time.LocalDate;

public record Usuario(int codigo, String nome, String senhaMd5, LocalDate validade, Integer empresa) {
}
