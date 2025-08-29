/* eslint-disable no-unused-vars */
import Topnav from "./Topnav";
import { Outlet } from "react-router-dom";
import Sidenav from "./Sidenav";
// import { GlobalStatesContext } from "../context/globalStates";
// import { useContext, useEffect } from "react";
// import GenericModal from "../modals/GenericModal";
// import CreateStudent from "../modals/CreateStudent";
// import CreateSubject from "../modals/CreateSubject";
// import toast, { Toaster } from "react-hot-toast";

const Home = () => {
  // const {
  //   toggleModal,
  //   setModal,
  //   toast: reactToast,
  // } = useContext(GlobalStatesContext);

  // console.log("we have msg for toast==>", reactToast?.show, reactToast?.msg);
  // const notify = () => toast.success(reactToast?.msg);

  return (
    <div className="row gx-0 ">
      <div className="col-md-2" style={{ zIndex: "99" }}>
        <Sidenav />
      </div>
      <div className="col col-md-10 d-flex flex-column p-2 px-0 mx-0">
        <Topnav />
        <Outlet />
      </div>

      {/* {toggleModal?.show && toggleModal?.action === "create-student" ? (
        <CreateStudent />
      ) : toggleModal?.show && toggleModal?.action === "create-subject" ? (
        <CreateSubject />
      ) : null} */}

      {/* =====toast notification====== */}
      {/* {reactToast?.show ? (
        toast?.success(reactToast?.msg)
      ) : null} */}
    </div>
  );
};

export default Home;
