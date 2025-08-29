import { Route, Routes } from "react-router-dom";
import AllProducts from "./components/AllProducts";
import NotFound from "./components/reusables/NotFound";
import {GlobalStatesProvider} from "./components/context/globalStates"
import Home from "./components/layout/Home";
import { useState } from "react";

function App() {
  const [user, setUser] = useState(true);

  return (
    <>
    <GlobalStatesProvider>
    <Routes>
      {/* <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} /> */}
      <Route
        path="/"
        element={user ? <Home /> : <Navigate to="not-found" />}
      >
        <Route index element={<AllProducts />} />
        {/* <Route path="/classes" element={<AllClasses />} /> */}
        {/* <Route path="/students" element={<Students />} />
        <Route path="/students/:student_id" element={<StudentPage/>} />
        <Route path="/schools/:schoolId" element={<AllClasses />} />
        <Route path="/trainers" element={<Trainers />} /> */}
      </Route>
      {/* <Route path="/results" element={<PrintAllResults />} /> */}
      <Route path="*" element={<NotFound />} />
    </Routes>
    {/* <Toaster/> */}
    </GlobalStatesProvider>
  </>
  )
}

export default App