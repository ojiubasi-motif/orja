import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
// ===========================================
import "@popperjs/core";
import "bootstrap";
import "bootstrap/dist/js/bootstrap";
import "bootstrap/dist/css/bootstrap.min.css";

import "./scss/styles.scss";

import { BrowserRouter, Route, Routes } from "react-router-dom";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
const queryClient = new QueryClient();

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      {/* <AuthProvider> */}
        <QueryClientProvider client={queryClient}>
          {/* <GlobalStatesProvider> */}
            <Routes>
              <Route path="/*" element={<App />} />
            </Routes>
          {/* </GlobalStatesProvider> */}
        </QueryClientProvider>
      {/* </AuthProvider> */}
    </BrowserRouter>
  </StrictMode>,
)
