/* eslint-disable no-unused-vars */
import { Link } from "react-router-dom";
import Logo from "../../../public/img/Orja.png";
import { useContext, useState } from "react";
import {navData} from "../constants/sidenav"
import {UserPlus,BookOpen,Edit3} from 'react-feather'
import { GlobalStatesContext } from "../context/globalStates";

const Sidenav = () => {
  const {toggleModal, setModal} = useContext(GlobalStatesContext)
  const [toggleNav, setToggle] = useState({
    student: false,
    subject: false,
    score: false,
  });
  return (
    <div className="col-md-2 p-0 fixed-top">
      {/* ======logo======== */}
      <div
        className="logo d-flex justify-content-between align-items-center p-2"
        style={{ cursor: "pointer", height: "60px" }}
      >
        <Link to="/" className="text-decoration-none">
          <span
            className="d-flex align-items-center ps-2"
            style={{ width: "70%" }}
          >
            <img
              className="mr-2"
              src={Logo}
              alt="logo-img"
              style={{ width: "35px", height: "35px" }}
            />
            <h6 className="fw-bold text-secondary mt-1">ReSchool</h6>
          </span>
        </Link>
      </div>
      {/* ===logo-end===== */}

      {/* ======nav items===== */}
      <ul className="px-3" >
        {navData?.map((item, index) =>
          item?.title == "Student" ? (
            <li className=" rounded my-1 p-2" style={{cursor:"pointer",backgroundColor:"#e4ebee"}} key={index}>
              <p
                className="p-0 m-0 fw-bold display-flex justify-content-start side-nav"
                onClick={() =>
                  setToggle({
                    ...toggleNav,
                    student: toggleNav?.student === true ? false : true,
                  })
                }
              >
                <UserPlus className="me-1" size={16}/>
                {item?.title}
              </p>
              {toggleNav?.student ? (
                <div className="side-nav-list ms-2 text-secondary">
                  {item?.items?.map((nav, i) => (
                    <p key={i} onClick={()=>setModal({...toggleModal, show:true, action:nav=="Create Student"?"create-student":"update-student",data:null})}>{nav}</p>
                  ))}
                </div>
              ) : null}
            </li>
          ) : item?.title == "Subject" ? (
            <li className="rounded my-1 p-2" key={index} style={{cursor:"pointer",backgroundColor:"#e4ebee"}}>
              <p
                className="display-flex justify-content-start side-nav p-0 m-0 fw-bold"
                onClick={() =>
                  setToggle({
                    ...toggleNav,
                    subject: toggleNav?.subject === true ? false : true,
                  })
                }
              >
                <BookOpen className="me-1" size={16}/>
                {item?.title}
              </p>
              {toggleNav?.subject ? (
                <div className="side-nav-list text-secondary ms-2">
                  {item?.items?.map((nav, i) => (
                    <p key={i} onClick={()=>setModal({...toggleModal, show:true, action:nav=="Create Subject"?"create-subject":"update-subject",data:null})}>{nav}</p>
                  ))}
                </div>
              ) : null}
            </li>
          ) : item?.title == "Score" ? (
            <li className="rounded my-1 p-2" style={{cursor:"pointer",backgroundColor:"#e4ebee"}} key={index}>
              <p
                className="display-flex justify-content-start side-nav p-0 m-0"
                onClick={() =>
                  setToggle({
                    ...toggleNav,
                    score: toggleNav?.score === true ? false : true,
                  })
                }
              >
                <Edit3 className="me-1" size={16}/>
                {item?.title}
              </p>
              {toggleNav?.score ? (
                <div className="side-nav-list text-secondary ms-2">
                  {item?.items?.map((nav, i) => (
                    <p key={i} onClick={()=>setModal({...toggleModal, show:true, action:nav})}>{nav}</p>
                  ))}
                </div>
              ) : null}
            </li>
          ) : null
        )}
      </ul>
      {/* ===nav-items end=== */}
    </div>
  );
};

export default Sidenav;